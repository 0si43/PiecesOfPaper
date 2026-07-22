import UIKit
import Testing
@testable import Pieces_of_Paper

@MainActor
struct NoteStoreLegacyTagsTests {
    let repositoryMock: NoteRepositoryMock
    let noteStore: NoteStore
    let notes = NoteRepositoryMock.TestFile.allCases.map { NoteData.createTestData(fileURL: $0.url) }

    init() {
        repositoryMock = NoteRepositoryMock(notes: notes)
        noteStore = NoteStore(
            noteRepository: repositoryMock,
            preferenceRepository: PreferenceRepositoryMock()
        )
    }

    @Test func test_loadNote_handsLegacyTagsToTheSalvageHook() async throws {
        let tag = TagEntity(name: "legacy", color: CodableUIColor(uiColor: .green))
        repositoryMock.notes[0].entity.legacyTags = [tag]
        var salvaged: [TagEntity] = []
        noteStore.onLegacyTagsDecoded = { salvaged = $0 }

        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first { $0.fileURL == notes[0].fileURL })
        _ = await noteStore.loadNote(entry)

        #expect(salvaged == [tag])
    }

    @Test func test_loadNote_doesNotCallSalvageHookForMigratedNotes() async throws {
        var called = false
        noteStore.onLegacyTagsDecoded = { _ in called = true }

        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        _ = await noteStore.loadNote(entry)

        #expect(!called)
    }
}
