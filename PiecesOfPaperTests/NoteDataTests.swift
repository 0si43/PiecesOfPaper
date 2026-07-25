import Foundation
import Testing
import PencilKit
@testable import Pieces_of_Paper

struct NoteDataTests {
    @Test func id_delegatesToEntityId() {
        let note = NoteData.createTestData()
        #expect(note.id == note.entity.id)
    }

    @Test func isArchived_trueForFileUnderArchivedDirectory() throws {
        let archivedUrl = try #require(FilePath.archivedUrl)
        let note = NoteData(entity: NoteEntity(drawing: PKDrawing()),
                            fileURL: archivedUrl.appendingPathComponent("test.pop"))
        #expect(note.isArchived)
    }

    @Test func isArchived_falseForFileOutsideArchivedDirectory() throws {
        let inboxUrl = try #require(FilePath.inboxUrl)
        let note = NoteData(entity: NoteEntity(drawing: PKDrawing()),
                            fileURL: inboxUrl.appendingPathComponent("test.pop"))
        #expect(!note.isArchived)
    }

    @Test func isInInbox_trueForFileUnderInboxDirectory() throws {
        let inboxUrl = try #require(FilePath.inboxUrl)
        let note = NoteData(entity: NoteEntity(drawing: PKDrawing()),
                            fileURL: inboxUrl.appendingPathComponent("test.pop"))
        #expect(note.isInInbox)
    }

    @Test func isInInbox_falseForFileOutsideInboxDirectory() throws {
        let note = NoteData(entity: NoteEntity(drawing: PKDrawing()),
                            fileURL: URL(fileURLWithPath: "/external/test.pop"))
        #expect(!note.isInInbox)
    }

    @Test func isInInbox_falseForSiblingDirectoryWithSharedPrefix() throws {
        let inboxUrl = try #require(FilePath.inboxUrl)
        let siblingUrl = URL(fileURLWithPath: inboxUrl.path + "2")
            .appendingPathComponent("test.pop")
        let note = NoteData(entity: NoteEntity(drawing: PKDrawing()), fileURL: siblingUrl)
        #expect(!note.isInInbox)
    }

    @Test func fallbackDirectory_classifiesByParentFolderName() {
        func note(atPath path: String) -> NoteData {
            NoteData(entity: NoteEntity(drawing: PKDrawing()), fileURL: URL(fileURLWithPath: path))
        }
        #expect(note(atPath: "/anywhere/InboxFolder/test.pop").fallbackDirectory == .inbox)
        #expect(note(atPath: "/anywhere/Archived/test.pop").fallbackDirectory == .archived)
        #expect(note(atPath: "/anywhere/Other/test.pop").fallbackDirectory == nil)
        #expect(note(atPath: "/anywhere/InboxFolder2/test.pop").fallbackDirectory == nil)
    }

    @Test func equatable_detectsEntityChange() {
        let note = NoteData.createTestData()
        var modified = note
        #expect(note == modified)
        modified.entity.tagIds.append(UUID())
        #expect(note != modified)
    }
}
