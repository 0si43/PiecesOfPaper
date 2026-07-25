import Testing
import Foundation
import PencilKit
@testable import Pieces_of_Paper

@MainActor
struct NoteRepositoryTests {
    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NoteRepositoryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func save_retargetsStaleLegacyUrlToMigratedFile() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let migratedUrl = directory.appendingPathComponent("note.pop")
        try PropertyListEncoder().encode(NoteEntity(drawing: PKDrawing())).write(to: migratedUrl)
        let staleUrl = directory.appendingPathComponent("note.plist")
        let entity = NoteEntity(drawing: PKDrawing())

        try await NoteRepository().save(entity, to: staleUrl)

        #expect(!FileManager.default.fileExists(atPath: staleUrl.path))
        let saved = try PropertyListDecoder().decode(NoteEntity.self,
                                                     from: Data(contentsOf: migratedUrl))
        #expect(saved.id == entity.id)
    }

    @Test func localFileAttributes_readsFileSystemDates() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileUrl = directory.appendingPathComponent("2024-01-02-03-04-051234.pop")
        try PropertyListEncoder().encode(NoteEntity(drawing: PKDrawing())).write(to: fileUrl)

        let attributes = NoteRepository().localFileAttributes(in: directory)

        #expect(attributes.count == 1)
        let attribute = try #require(attributes.first)
        #expect(attribute.fileURL == fileUrl)
        let modificationDate = try #require(attribute.contentModificationDate)
        #expect(abs(modificationDate.timeIntervalSinceNow) < 10)
        #expect(attribute.creationDate != nil)
    }

    @Test func open_readsSavedEntity() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileUrl = directory.appendingPathComponent("note.pop")
        let entity = NoteEntity(drawing: PKDrawing.stub())
        try PropertyListEncoder().encode(entity).write(to: fileUrl)

        let note = try await NoteRepository().open(fileUrl: fileUrl)

        #expect(note.entity.id == entity.id)
        #expect(note.entity.drawing == entity.drawing)
        #expect(note.fileURL == fileUrl)
    }

    // A missing local file fails fast; only genuine ubiquitous items are
    // allowed to wait for their download inside open()
    @Test func open_throwsForMissingNonUbiquitousFile() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        await #expect(throws: NoteRepositoryError.self) {
            _ = try await NoteRepository().open(fileUrl: directory.appendingPathComponent("missing.pop"))
        }
    }

    @Test func open_throwsForCorruptFile() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let corruptUrl = directory.appendingPathComponent("corrupt.pop")
        try Data("not a property list".utf8).write(to: corruptUrl)

        await #expect(throws: NoteRepositoryError.self) {
            _ = try await NoteRepository().open(fileUrl: corruptUrl)
        }
    }

    @Test func delete_removesTheFile() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileUrl = directory.appendingPathComponent("note.pop")
        try PropertyListEncoder().encode(NoteEntity(drawing: PKDrawing())).write(to: fileUrl)

        try await NoteRepository().delete(fileUrl: fileUrl)

        #expect(!FileManager.default.fileExists(atPath: fileUrl.path))
    }

    @Test func delete_throwsWhenTheFileIsMissing() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        await #expect(throws: (any Error).self) {
            try await NoteRepository().delete(fileUrl: directory.appendingPathComponent("missing.pop"))
        }
    }

    @Test func move_relocatesTheFileAndReturnsItsNewUrl() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("source")
        let destination = directory.appendingPathComponent("destination")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let fileUrl = source.appendingPathComponent("note.pop")
        let entity = NoteEntity(drawing: PKDrawing())
        try PropertyListEncoder().encode(entity).write(to: fileUrl)

        let newUrl = try await NoteRepository().move(fileUrl: fileUrl, toDirectoryAt: destination)

        #expect(newUrl.lastPathComponent == "note.pop")
        #expect(newUrl.deletingLastPathComponent().path == destination.path)
        #expect(!FileManager.default.fileExists(atPath: fileUrl.path))
        let moved = try PropertyListDecoder().decode(NoteEntity.self, from: Data(contentsOf: newUrl))
        #expect(moved.id == entity.id)
    }

    @Test func move_throwsWhenTheSourceIsMissing() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appendingPathComponent("destination")
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        await #expect(throws: (any Error).self) {
            _ = try await NoteRepository().move(fileUrl: directory.appendingPathComponent("missing.pop"),
                                                toDirectoryAt: destination)
        }
    }

    // A fresh container starts without InboxFolder/Archived; the first save
    // must not fail on the missing parent
    @Test func save_createsMissingParentDirectory() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileUrl = directory.appendingPathComponent("nested/InboxFolder/note.pop")
        let entity = NoteEntity(drawing: PKDrawing.stub())

        try await NoteRepository().save(entity, to: fileUrl)

        let saved = try PropertyListDecoder().decode(NoteEntity.self, from: Data(contentsOf: fileUrl))
        #expect(saved.id == entity.id)
    }

    // The thrown error carries the reason captured via UIDocument.handleError,
    // which the completion Bool alone never exposes
    @Test func save_throwsWithUnderlyingReasonWhenWriteFails() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        // A plain file occupies the parent path, so the write cannot succeed
        let blocker = directory.appendingPathComponent("blocked")
        try Data().write(to: blocker)
        let fileUrl = blocker.appendingPathComponent("note.pop")

        do {
            try await NoteRepository().save(NoteEntity(drawing: PKDrawing()), to: fileUrl)
            Issue.record("save should throw for an unwritable target")
        } catch let error as NoteRepositoryError {
            guard case .saveFailed(_, let underlying) = error else {
                Issue.record("unexpected error case: \(error)")
                return
            }
            #expect(underlying != nil)
        }
    }

    @Test func save_writesToLegacyUrlWhileItStillExists() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let legacyUrl = directory.appendingPathComponent("note.plist")
        try PropertyListEncoder().encode(NoteEntity(drawing: PKDrawing())).write(to: legacyUrl)
        let entity = NoteEntity(drawing: PKDrawing())

        try await NoteRepository().save(entity, to: legacyUrl)

        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("note.pop").path))
        let saved = try PropertyListDecoder().decode(NoteEntity.self,
                                                     from: Data(contentsOf: legacyUrl))
        #expect(saved.id == entity.id)
    }
}
