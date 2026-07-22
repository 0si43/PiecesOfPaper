import Testing
import Foundation
@testable import Pieces_of_Paper

struct LegacyNoteMigratorTests {
    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LegacyNoteMigratorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func migrate_renamesLegacyFilePreservingContents() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let contents = Data("note-body".utf8)
        try contents.write(to: directory.appendingPathComponent("note.plist"))

        LegacyNoteMigrator.migrate(in: directory)

        let renamedUrl = directory.appendingPathComponent("note.pop")
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("note.plist").path))
        #expect(try Data(contentsOf: renamedUrl) == contents)
    }

    @Test func migrate_isIdempotent() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("note-body".utf8).write(to: directory.appendingPathComponent("note.plist"))

        LegacyNoteMigrator.migrate(in: directory)
        LegacyNoteMigrator.migrate(in: directory)

        let fileNames = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        #expect(fileNames == ["note.pop"])
    }

    @Test func migrate_skipsWhenDestinationAlreadyExists() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let legacyContents = Data("legacy".utf8)
        let migratedContents = Data("migrated".utf8)
        try legacyContents.write(to: directory.appendingPathComponent("note.plist"))
        try migratedContents.write(to: directory.appendingPathComponent("note.pop"))

        LegacyNoteMigrator.migrate(in: directory)

        #expect(try Data(contentsOf: directory.appendingPathComponent("note.plist")) == legacyContents)
        #expect(try Data(contentsOf: directory.appendingPathComponent("note.pop")) == migratedContents)
    }

    @Test func migrate_missingDirectoryDoesNothing() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LegacyNoteMigratorTests-missing-\(UUID().uuidString)")

        LegacyNoteMigrator.migrate(in: directory)

        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }

    @Test func migrate_ignoresUnrelatedAndHiddenFiles() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("json".utf8).write(to: directory.appendingPathComponent("taglist.json"))
        try Data("hidden".utf8).write(to: directory.appendingPathComponent(".hidden.plist"))
        try Data("pop".utf8).write(to: directory.appendingPathComponent("note.pop"))

        LegacyNoteMigrator.migrate(in: directory)

        let fileNames = try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
        #expect(fileNames == [".hidden.plist", "note.pop", "taglist.json"])
    }
}
