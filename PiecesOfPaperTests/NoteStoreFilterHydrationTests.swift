import Foundation
import Testing
import PencilKit
@testable import Pieces_of_Paper

@MainActor
struct NoteStoreFilterHydrationTests {
    var noteStore: NoteStore
    let repositoryMock: NoteRepositoryMock
    let tag = TagEntity(name: "work", color: CodableUIColor(uiColor: .blue))

    init() {
        var tagged = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
        tagged.entity.tags = [tag]
        let others = [NoteRepositoryMock.TestFile.file2, .file3].map {
            NoteData.createTestData(fileURL: $0.url)
        }
        repositoryMock = NoteRepositoryMock(notes: [tagged] + others)
        noteStore = NoteStore(
            noteRepository: repositoryMock,
            preferenceRepository: PreferenceRepositoryMock(),
            metadataCacheRepository: NoteMetadataCacheRepositoryMock()
        )
    }

    private var filterOrder: ListOrder {
        var order = ListOrder()
        order.filterBy = [tag]
        return order
    }

    private func waitUntilHydrated() async {
        for _ in 0..<500 where noteStore.isFilterHydrating(for: .inbox) {
            await Task.yield()
        }
    }

    @Test func test_activatingFilter_hydratesAllEntriesAndShowsMatches() async {
        await noteStore.fetch(directory: .inbox)
        #expect(repositoryMock.openCallCount == 0)

        noteStore.setListOrder(filterOrder, for: .inbox)
        #expect(noteStore.isFilterHydrating(for: .inbox))
        await waitUntilHydrated()

        #expect(repositoryMock.openCallCount == 3)
        #expect(noteStore.displayInboxEntries.map(\.fileURL) == [NoteRepositoryMock.TestFile.file1.url])
        #expect(!noteStore.isFilterHydrating(for: .inbox))
    }

    @Test func test_reactivatingFilter_skipsAlreadyLoadedMetadata() async {
        await noteStore.fetch(directory: .inbox)
        noteStore.setListOrder(filterOrder, for: .inbox)
        await waitUntilHydrated()
        #expect(repositoryMock.openCallCount == 3)

        noteStore.setListOrder(ListOrder(), for: .inbox)
        noteStore.setListOrder(filterOrder, for: .inbox)
        await waitUntilHydrated()

        #expect(repositoryMock.openCallCount == 3)
        #expect(noteStore.displayInboxEntries.map(\.fileURL) == [NoteRepositoryMock.TestFile.file1.url])
    }

    @Test func test_fetchWithActiveFilter_reopensOnlyChangedFile() async {
        await noteStore.fetch(directory: .inbox)
        noteStore.setListOrder(filterOrder, for: .inbox)
        await waitUntilHydrated()
        #expect(repositoryMock.openCallCount == 3)

        let changed = NoteRepositoryMock.TestFile.file2
        repositoryMock.enumeratedAttributes = NoteRepositoryMock.TestFile.allCases.map {
            NoteFileAttributes(fileURL: $0.url,
                               creationDate: nil,
                               contentModificationDate: $0 == changed
                                   ? Date(timeIntervalSince1970: 9_000)
                                   : $0.contentModificationDate)
        }
        await noteStore.fetch(directory: .inbox, background: true)
        await waitUntilHydrated()

        #expect(repositoryMock.openCallCount == 4)
    }

    @Test func test_clearingFilter_stopsHydration() async {
        await noteStore.fetch(directory: .inbox)
        noteStore.setListOrder(filterOrder, for: .inbox)
        #expect(noteStore.isFilterHydrating(for: .inbox))

        noteStore.setListOrder(ListOrder(), for: .inbox)
        #expect(!noteStore.isFilterHydrating(for: .inbox))
        #expect(noteStore.displayInboxEntries.count == 3)
    }
}
