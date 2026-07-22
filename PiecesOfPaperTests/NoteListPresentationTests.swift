import Testing
@testable import Pieces_of_Paper

@MainActor
struct NoteListPresentationTests {
    let presentation = NoteListPresentation()
    var noteStore: NoteStore
    let repositoryMock: NoteRepositoryMock
    let notes = NoteRepositoryMock.TestFile.allCases.map { NoteData.createTestData(fileURL: $0.url) }

    init() {
        repositoryMock = NoteRepositoryMock(notes: notes)
        noteStore = NoteStore(
            noteRepository: repositoryMock,
            preferenceRepository: PreferenceRepositoryMock(),
            metadataCacheRepository: NoteMetadataCacheRepositoryMock()
        )
    }

    @Test func test_requestTag_opensNoteAndPresentsSheet() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        presentation.requestTag(entry, from: noteStore)
        for _ in 0..<100 where presentation.noteToTag == nil {
            await Task.yield()
        }
        #expect(presentation.noteToTag?.fileURL == entry.fileURL)
        #expect(presentation.alert == nil)
    }

    @Test func test_requestShare_alertsWhenOpenFails() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        repositoryMock.failingUrls = [entry.fileURL]
        presentation.requestShare(entry, from: noteStore)
        for _ in 0..<100 where presentation.alert == nil {
            await Task.yield()
        }
        #expect(presentation.isAlertPresented)
        #expect(presentation.noteToShare == nil)
    }

    @Test func test_isAlertPresented_clearsTheAlertWhenSetToFalse() {
        presentation.alert = .archiveAll
        #expect(presentation.isAlertPresented)
        presentation.isAlertPresented = false
        #expect(presentation.alert == nil)
    }
}
