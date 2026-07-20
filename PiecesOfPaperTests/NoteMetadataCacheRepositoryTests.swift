import Foundation
import Testing
@testable import Pieces_of_Paper

struct NoteMetadataCacheRepositoryTests {
    private let fileUrl = FileManager.default.temporaryDirectory
        .appendingPathComponent("note-metadata-cache-\(UUID().uuidString).json")

    private var metadata: NoteMetadata {
        NoteMetadata(id: UUID(),
                     tags: [TagEntity(name: "work", color: CodableUIColor(uiColor: .blue))],
                     updatedDate: Date(timeIntervalSince1970: 1_000))
    }

    @Test func test_save_thenLoad_returnsTheSameEntries() throws {
        let repository = NoteMetadataCacheRepository(fileUrl: fileUrl)
        let saved = metadata
        repository.save(["note.pop": saved])

        let loaded = NoteMetadataCacheRepository(fileUrl: fileUrl).load()

        #expect(loaded.count == 1)
        #expect(loaded["note.pop"] == saved)
        try FileManager.default.removeItem(at: fileUrl)
    }

    @Test func test_load_returnsEmptyWhenTheFileIsMissing() {
        #expect(NoteMetadataCacheRepository(fileUrl: fileUrl).load().isEmpty)
    }

    @Test func test_load_returnsEmptyForAnUnknownVersion() throws {
        let entries = try JSONEncoder().encode(["note.pop": metadata])
        // swiftlint:disable:next force_unwrapping
        let entriesJson = String(data: entries, encoding: .utf8)!
        let json = #"{"version": 99, "entries": \#(entriesJson)}"#
        try Data(json.utf8).write(to: fileUrl)

        #expect(NoteMetadataCacheRepository(fileUrl: fileUrl).load().isEmpty)
        try FileManager.default.removeItem(at: fileUrl)
    }

    @Test func test_load_returnsEmptyForACorruptFile() throws {
        try Data("not json".utf8).write(to: fileUrl)

        #expect(NoteMetadataCacheRepository(fileUrl: fileUrl).load().isEmpty)
        try FileManager.default.removeItem(at: fileUrl)
    }
}
