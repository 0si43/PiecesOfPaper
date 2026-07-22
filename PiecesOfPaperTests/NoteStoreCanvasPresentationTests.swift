import Foundation
import Testing
import PencilKit
@testable import Pieces_of_Paper

@MainActor
struct NoteStoreCanvasPresentationTests {
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

    @Test func test_openNewNote_presentsBlankNoteInInbox() throws {
        noteStore.openNewNote()
        let opened = try #require(noteStore.openedNote)
        #expect(opened.isInInbox)
        #expect(opened.entity.drawing.strokes.isEmpty)
    }

    @Test func test_openBlankNoteIfIdle_opensBlankNoteWhenIdle() {
        noteStore.openBlankNoteIfIdle()
        #expect(noteStore.openedNote != nil)
    }

    @Test func test_openBlankNoteIfIdle_skipsWhenNoteAlreadyOpen() {
        let note = NoteData.createTestData()
        noteStore.openedNote = note
        noteStore.openBlankNoteIfIdle()
        #expect(noteStore.openedNote == note)
    }

    @Test func test_handleIncomingURL_ignoresNonPopExtension() {
        noteStore.handleIncomingURL(URL(fileURLWithPath: "/external/legacy.plist"))
        #expect(noteStore.externalOpenTask == nil)
        #expect(!noteStore.isHandlingExternalOpen)
        #expect(noteStore.openedNote == nil)
    }

    @Test func test_handleIncomingURL_opensPopFileOnCanvas() async {
        noteStore.handleIncomingURL(NoteRepositoryMock.externalUrl)
        #expect(noteStore.isHandlingExternalOpen)
        await noteStore.externalOpenTask?.value
        #expect(noteStore.openedNote == notes[0])
        #expect(!noteStore.isHandlingExternalOpen)
    }

    @Test func test_openExternalNote_showsAlertOnFailure() async {
        repositoryMock.failingUrls = [NoteRepositoryMock.externalUrl]
        await noteStore.openExternalNote(url: NoteRepositoryMock.externalUrl)
        #expect(noteStore.openedNote == nil)
        #expect(noteStore.showExternalOpenAlert)
    }

    @Test func test_openExternalNote_replacesOpenedNote() async {
        noteStore.openNewNote()
        await noteStore.openExternalNote(url: NoteRepositoryMock.externalUrl)
        #expect(noteStore.openedNote == notes[0])
    }

    @Test func test_handleIncomingURL_secondRapidOpenWins() async {
        noteStore.handleIncomingURL(NoteRepositoryMock.externalUrl)
        let firstTask = noteStore.externalOpenTask
        noteStore.handleIncomingURL(NoteRepositoryMock.externalUrl2)
        await firstTask?.value
        await noteStore.externalOpenTask?.value
        #expect(noteStore.openedNote == notes[1])
        #expect(!noteStore.isHandlingExternalOpen)
    }

    @Test func test_openExternalNote_keepsNoteTheUserOpenedDuringSlowOpen() async {
        repositoryMock.suspendOpens = true
        noteStore.handleIncomingURL(NoteRepositoryMock.externalUrl)
        while !repositoryMock.hasPendingOpen { await Task.yield() }

        let userNote = NoteData.createTestData()
        noteStore.openedNote = userNote
        repositoryMock.suspendOpens = false
        repositoryMock.resumePendingOpens()
        await noteStore.externalOpenTask?.value

        #expect(noteStore.openedNote == userNote)
        #expect(!noteStore.isHandlingExternalOpen)
    }

    @Test func test_openBlankNoteIfIdle_skipsWhileHandlingExternalOpen() async {
        noteStore.handleIncomingURL(NoteRepositoryMock.externalUrl)
        noteStore.openBlankNoteIfIdle()
        await noteStore.externalOpenTask?.value
        #expect(noteStore.openedNote == notes[0])
    }
}
