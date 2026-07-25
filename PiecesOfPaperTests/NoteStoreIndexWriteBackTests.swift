import UIKit
import Testing
import PencilKit
@testable import Pieces_of_Paper

// applySaved feeds the index directly, without enumeration
@MainActor
struct NoteStoreIndexWriteBackTests {
    var noteStore: NoteStore
    let repositoryMock: NoteRepositoryMock

    init() {
        repositoryMock = NoteRepositoryMock(
            notes: NoteRepositoryMock.TestFile.allCases.map { NoteData.createTestData(fileURL: $0.url) }
        )
        noteStore = NoteStore(
            noteRepository: repositoryMock,
            preferenceRepository: PreferenceRepositoryMock(),
            metadataCacheRepository: NoteMetadataCacheRepositoryMock()
        )
    }

    @Test func test_applySaved_insertsEntryAndMetadata() {
        let note = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
        noteStore.applySaved(note)
        #expect(noteStore.inboxIndex.map(\.fileURL) == [note.fileURL])
        #expect(noteStore.metadataByFileName[note.fileName]?.id == note.entity.id)
    }

    @Test func test_applySaved_insertsArchivedNoteIntoArchivedIndex() throws {
        let archivedUrl = try #require(FilePath.archivedUrl).appendingPathComponent("2024-05-06-07-08-090000.pop")
        let note = NoteData.createTestData(fileURL: archivedUrl)
        noteStore.applySaved(note)
        #expect(noteStore.archivedIndex.map(\.fileURL) == [archivedUrl])
        #expect(noteStore.inboxIndex.isEmpty)
    }

    @Test func test_applySaved_ignoresFileOutsideManagedDirectories() {
        let note = NoteData.createTestData(fileURL: URL(fileURLWithPath: "/external/note.pop"))
        noteStore.applySaved(note)
        #expect(noteStore.inboxIndex.isEmpty)
        #expect(noteStore.archivedIndex.isEmpty)
    }

    // A note saved into a managed folder of another container (the storage
    // location changed mid-session, issue #225) is still listed
    @Test func test_applySaved_fallsBackToFolderNameForForeignContainer() {
        let foreignInboxUrl = URL(fileURLWithPath: "/other-container/InboxFolder/note.pop")
        noteStore.applySaved(NoteData.createTestData(fileURL: foreignInboxUrl))
        #expect(noteStore.inboxIndex.map(\.fileURL) == [foreignInboxUrl])
        #expect(noteStore.archivedIndex.isEmpty)

        let foreignArchivedUrl = URL(fileURLWithPath: "/other-container/Archived/note.pop")
        noteStore.applySaved(NoteData.createTestData(fileURL: foreignArchivedUrl))
        #expect(noteStore.archivedIndex.map(\.fileURL) == [foreignArchivedUrl])
    }

    @Test func test_applySaved_thenFetchDoesNotDuplicate() async {
        noteStore.applySaved(NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url))
        await noteStore.fetch(directory: .inbox)
        #expect(noteStore.inboxIndex.count == 3)
        #expect(noteStore.inboxIndex.filter { $0.fileURL == NoteRepositoryMock.TestFile.file1.url }.count == 1)
    }

    @Test func test_canRequestReview_requiresFiveInboxEntries() {
        (0..<4).forEach { _ in
            noteStore.applySaved(NoteData.createTestData())
        }
        #expect(!noteStore.canRequestReview)
        noteStore.applySaved(NoteData.createTestData())
        #expect(noteStore.canRequestReview)
    }
}
