import Testing
import Foundation
@testable import Pieces_of_Paper

@MainActor
struct TagRepositoryTests {
    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TagRepositoryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func tagListUrl(in directory: URL) -> URL {
        directory.appendingPathComponent("Library").appendingPathComponent("taglist.json")
    }

    private func placeholderUrl(in directory: URL) -> URL {
        directory.appendingPathComponent("Library").appendingPathComponent(".taglist.json.icloud")
    }

    private func makeTags() -> [TagEntity] {
        [TagEntity(name: "work", color: CodableUIColor(uiColor: .systemRed)),
         TagEntity(name: "home", color: CodableUIColor(uiColor: .systemBlue))]
    }

    // MARK: - TagListFileState

    @Test func state_isAbsent_whenNeitherFileNorPlaceholderExists() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(TagListFileState.check(for: tagListUrl(in: directory)) == .absent)
    }

    @Test func state_isDownloaded_whenFileExists() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileUrl = tagListUrl(in: directory)
        try FileManager.default.createDirectory(at: fileUrl.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try JSONEncoder().encode(makeTags()).write(to: fileUrl)

        #expect(TagListFileState.check(for: fileUrl) == .downloaded)
    }

    @Test func state_isInCloudOnly_whenOnlyPlaceholderExists() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let placeholder = placeholderUrl(in: directory)
        try FileManager.default.createDirectory(at: placeholder.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data().write(to: placeholder)

        #expect(TagListFileState.check(for: tagListUrl(in: directory)) == .inCloudOnly)
    }

    // MARK: - fetchAll

    @Test func fetchAll_loadsTags_whenFileExists() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileUrl = tagListUrl(in: directory)
        try FileManager.default.createDirectory(at: fileUrl.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let tags = makeTags()
        try JSONEncoder().encode(tags).write(to: fileUrl)

        #expect(await TagRepository(tagListFileUrl: fileUrl).fetchAll() == tags)
    }

    // Regression test for #199: an undownloaded iCloud copy must be treated as
    // "still downloading", not "missing" — no defaults returned, nothing written.
    @Test func fetchAll_returnsEmptyAndWritesNothing_whenOnlyPlaceholderExists() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let placeholder = placeholderUrl(in: directory)
        try FileManager.default.createDirectory(at: placeholder.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data().write(to: placeholder)
        let fileUrl = tagListUrl(in: directory)

        #expect(await TagRepository(tagListFileUrl: fileUrl).fetchAll() == [])
        #expect(!FileManager.default.fileExists(atPath: fileUrl.path))
    }

    @Test func fetchAll_returnsDefaultsWithoutCreatingFile_whenAbsent() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileUrl = tagListUrl(in: directory)

        let tags = await TagRepository(tagListFileUrl: fileUrl).fetchAll()

        #expect(tags.count == 4)
        #expect(!FileManager.default.fileExists(atPath: fileUrl.path))
    }

    @Test func fetchAll_returnsStableDefaultIds_acrossInstances() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileUrl = tagListUrl(in: directory)

        let first = await TagRepository(tagListFileUrl: fileUrl).fetchAll()
        let second = await TagRepository(tagListFileUrl: fileUrl).fetchAll()

        #expect(first.map(\.id) == second.map(\.id))
    }

    // MARK: - saveAll

    @Test func saveAll_refusesToWrite_whenOnlyPlaceholderExists() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let placeholder = placeholderUrl(in: directory)
        try FileManager.default.createDirectory(at: placeholder.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data().write(to: placeholder)
        let fileUrl = tagListUrl(in: directory)

        #expect(await !TagRepository(tagListFileUrl: fileUrl).saveAll(makeTags()))
        #expect(!FileManager.default.fileExists(atPath: fileUrl.path))
        #expect(FileManager.default.fileExists(atPath: placeholder.path))
    }

    @Test func saveAll_createsLibraryDirectoryAndRoundTrips() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileUrl = tagListUrl(in: directory)
        let repository = TagRepository(tagListFileUrl: fileUrl)
        let tags = makeTags()

        #expect(await repository.saveAll(tags))
        #expect(await repository.fetchAll() == tags)
    }
}
