import UIKit
import Testing
import PencilKit
@testable import Pieces_of_Paper

// The canvas save path has its own suite: it feeds the index through
// applySaved rather than enumeration
@MainActor
struct NoteStoreSaveDrawingTests {
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

    @Test func test_saveDrawing_skipsWhenDrawingUnchanged() async throws {
        let note = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
        let saved = try await noteStore.save(drawing: note.entity.drawing, to: note)
        #expect(saved == note)
        #expect(noteStore.inboxIndex.isEmpty)
        #expect(repositoryMock.saveCallCount == 0)
    }

    @Test func test_saveDrawing_persistsAndUpdatesIndexOnSuccess() async throws {
        let note = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
        let drawing = PKDrawing.stub()
        let saved = try await noteStore.save(drawing: drawing, to: note)
        #expect(saved.entity.drawing == drawing)
        #expect(saved.entity.updatedDate > note.entity.updatedDate)
        let entry = try #require(noteStore.inboxIndex.first { $0.fileURL == note.fileURL })
        #expect(entry.updatedDate == saved.entity.updatedDate)
        #expect(noteStore.metadataByFileName[note.fileName]?.id == note.entity.id)
    }

    @Test func test_saveDrawing_throwsAndKeepsIndexOnFailure() async {
        repositoryMock.saveShouldSucceed = false
        let note = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
        await #expect(throws: NoteRepositoryError.self) {
            try await noteStore.save(drawing: PKDrawing.stub(), to: note)
        }
        #expect(noteStore.inboxIndex.isEmpty)
    }

    @Test func test_saveDrawing_mergesTagsFromMetadataCache() async throws {
        await noteStore.fetch(directory: .inbox)
        let staleSnapshot = notes[0]
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        try await noteStore.addTag(tag, to: staleSnapshot)

        let saved = try await noteStore.save(drawing: PKDrawing.stub(), to: staleSnapshot)

        #expect(saved.entity.tagIds == [tag.id])
        #expect(noteStore.currentTagIds(for: staleSnapshot) == [tag.id])
    }
}
