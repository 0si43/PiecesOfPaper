import UIKit
import Testing
@testable import Pieces_of_Paper

/// The list reads a row's tags from the metadata cache. On iCloud the index
/// entry's date comes from the metadata query while the cache's comes from the
/// local file, so the two are never guaranteed to agree.
@MainActor
struct NoteStoreTagDisplayTests {
    private let note = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
    private let tag = TagEntity(name: "idea", color: CodableUIColor(uiColor: .systemYellow))
    private let repositoryMock: NoteRepositoryMock
    private let noteStore: NoteStore

    init() {
        repositoryMock = NoteRepositoryMock(notes: [note])
        noteStore = NoteStore(noteRepository: repositoryMock,
                              preferenceRepository: PreferenceRepositoryMock(),
                              metadataCacheRepository: NoteMetadataCacheRepositoryMock())
    }

    private var entry: NoteIndexEntry? {
        noteStore.inboxIndex.first { $0.fileURL == note.fileURL }
    }

    private func attributes(modifiedAt date: Date) -> NoteFileAttributes {
        NoteFileAttributes(fileURL: note.fileURL, creationDate: nil, contentModificationDate: date)
    }

    /// The filter reads the same cache, so it loses the note in the same case.
    /// The filter is set directly rather than through `setListOrder`, which
    /// would start a hydration pass and re-open the document mid-assertion.
    @Test func test_tagFilter_survivesAnEnumerationThatReportsADifferentDate() async throws {
        await noteStore.fetch(directory: .inbox)
        repositoryMock.savedFileAttributes[note.fileURL] = attributes(modifiedAt: Date(timeIntervalSince1970: 5_000))
        try await noteStore.addTag(tag, to: note)

        repositoryMock.enumeratedAttributes = [attributes(modifiedAt: Date(timeIntervalSince1970: 5_001))]
        await noteStore.applyCloudUpdate()
        noteStore.inboxListOrder.filterBy = [tag]

        #expect(noteStore.displayEntries(for: .inbox).map(\.fileURL) == [note.fileURL])
    }

    @Test func test_tagIds_surviveAnEnumerationThatReportsADifferentDate() async throws {
        await noteStore.fetch(directory: .inbox)
        // The write-back records the local file's date
        repositoryMock.savedFileAttributes[note.fileURL] = attributes(modifiedAt: Date(timeIntervalSince1970: 5_000))
        try await noteStore.addTag(tag, to: note)

        // The metadata query then reports its own date for the same file
        repositoryMock.enumeratedAttributes = [attributes(modifiedAt: Date(timeIntervalSince1970: 5_001))]
        await noteStore.applyCloudUpdate()

        #expect(noteStore.tagIds(for: try #require(entry)) == [tag.id])
    }
}
