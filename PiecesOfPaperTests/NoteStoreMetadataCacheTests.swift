import Foundation
import Testing
@testable import Pieces_of_Paper

@MainActor
struct NoteStoreMetadataCacheTests {
    let repositoryMock: NoteRepositoryMock
    let cacheMock: NoteMetadataCacheRepositoryMock
    let tag: TagEntity

    init() {
        let tag = TagEntity(name: "work", color: CodableUIColor(uiColor: .blue))
        self.tag = tag
        var tagged = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
        tagged.entity.tagIds = [tag.id]
        let others = [NoteRepositoryMock.TestFile.file2, .file3].map {
            NoteData.createTestData(fileURL: $0.url)
        }
        repositoryMock = NoteRepositoryMock(notes: [tagged] + others)
        // Every note's metadata already on disk, as after a previous launch
        cacheMock = NoteMetadataCacheRepositoryMock(
            entries: Dictionary(uniqueKeysWithValues: NoteRepositoryMock.TestFile.allCases.map { file in
                (file.url.lastPathComponent,
                 NoteMetadata(id: UUID(),
                              tagIds: file == .file1 ? [tag.id] : [],
                              updatedDate: file.contentModificationDate))
            })
        )
    }

    private func makeStore() -> NoteStore {
        NoteStore(noteRepository: repositoryMock,
                  preferenceRepository: PreferenceRepositoryMock(),
                  metadataCacheRepository: cacheMock)
    }

    private var filterOrder: ListOrder {
        var order = ListOrder()
        order.filterBy = [tag]
        return order
    }

    private func waitUntilHydrated(_ store: NoteStore) async {
        for _ in 0..<500 where store.isFilterHydrating(for: .inbox) {
            await Task.yield()
        }
    }

    @Test func test_persistedCache_filtersByTagWithoutOpeningDocuments() async {
        let store = makeStore()
        await store.fetch(directory: .inbox)

        store.setListOrder(filterOrder, for: .inbox)
        await waitUntilHydrated(store)

        #expect(repositoryMock.openCallCount == 0)
        #expect(store.displayInboxEntries.map(\.fileURL) == [NoteRepositoryMock.TestFile.file1.url])
    }

    @Test func test_persistedCache_reopensOnlyTheFileChangedSinceItWasWritten() async {
        let changed = NoteRepositoryMock.TestFile.file2
        repositoryMock.enumeratedAttributes = NoteRepositoryMock.TestFile.allCases.map {
            NoteFileAttributes(fileURL: $0.url,
                               creationDate: nil,
                               contentModificationDate: $0 == changed
                                   ? Date(timeIntervalSince1970: 9_000)
                                   : $0.contentModificationDate)
        }
        let store = makeStore()
        await store.fetch(directory: .inbox)

        store.setListOrder(filterOrder, for: .inbox)
        await waitUntilHydrated(store)

        #expect(repositoryMock.openCallCount == 1)
        #expect(store.displayInboxEntries.map(\.fileURL) == [NoteRepositoryMock.TestFile.file1.url])
    }

    @Test func test_flush_writesTheCurrentMetadata() async throws {
        let store = makeStore()
        await store.loadPersistedMetadataTask?.value
        await store.fetch(directory: .inbox)
        let entry = try #require(store.inboxIndex.first)
        _ = await store.loadNote(entry)

        store.flushMetadataCache()
        await store.persistTask?.value

        #expect(cacheMock.saveCount >= 1)
        #expect(cacheMock.savedEntries[entry.fileName]?.tagIds == [tag.id])
    }

    @Test func test_flush_dropsEntriesThatAreNoLongerListed() async throws {
        let store = makeStore()
        await store.loadPersistedMetadataTask?.value
        await store.fetch(directory: .inbox)
        let entry = try #require(store.inboxIndex.first)
        // A note opened in place from the Files app is never listed
        let foreign = NoteIndexEntry(fileURL: NoteRepositoryMock.externalUrl,
                                     creationDate: nil,
                                     contentModificationDate: nil)
        _ = await store.loadNote(foreign)
        try await store.delete(entry)

        store.flushMetadataCache()
        await store.persistTask?.value

        #expect(cacheMock.savedEntries[entry.fileName] == nil)
        #expect(cacheMock.savedEntries[foreign.fileName] == nil)
        #expect(cacheMock.savedEntries.count == 2)
    }
}
