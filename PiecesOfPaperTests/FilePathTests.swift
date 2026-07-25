import Testing
import Foundation
@testable import Pieces_of_Paper

struct FilePathTests {
    // A freshly generated file name parses back to (approximately) now
    @Test func parseTimestamp_roundTripsGeneratedFileName() {
        let name = FilePath.fileName
        let parsed = FilePath.parseTimestamp(fromFileName: name)
        #expect(parsed != nil)
        if let parsed {
            #expect(abs(parsed.timeIntervalSinceNow) < 5)
        }
    }

    // A known timestamp maps to the expected calendar components
    @Test func parseTimestamp_parsesKnownTimestamp() throws {
        let parsed = try #require(FilePath.parseTimestamp(fromFileName: "2024-01-02-03-04-051234.pop"))
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: parsed
        )
        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 2)
        #expect(components.hour == 3)
        #expect(components.minute == 4)
        #expect(components.second == 5)
    }

    // Legacy .plist names share the same timestamp stem
    @Test func parseTimestamp_parsesLegacyPlistName() {
        #expect(FilePath.parseTimestamp(fromFileName: "2021-11-23-09-15-301234.plist") != nil)
    }

    // The metadata cache is derived data: it belongs in Caches, never under the
    // synced savingUrl, and is written to a real, writable location
    @Test func noteMetadataCacheFileUrl_isAWritableFileInCaches() throws {
        let url = try #require(FilePath.noteMetadataCacheFileUrl)
        let cachesPath = try #require(
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        ).path
        #expect(url.deletingLastPathComponent().path == cachesPath)
        #expect(["note-metadata-cache-local.json", "note-metadata-cache-icloud.json"]
            .contains(url.lastPathComponent))

        try Data("{}".utf8).write(to: url)
        #expect(FileManager.default.fileExists(atPath: url.path))
        try FileManager.default.removeItem(at: url)
    }

    // Non-timestamp names return nil instead of a garbage date
    @Test func parseTimestamp_returnsNilForNonTimestampName() {
        #expect(FilePath.parseTimestamp(fromFileName: "IMG_1234.pop") == nil)
        #expect(FilePath.parseTimestamp(fromFileName: "note.pop") == nil)
        #expect(FilePath.parseTimestamp(fromFileName: "") == nil)
    }
}

// Serialized: the cases mutate FilePath's shared cache and provider seam
@Suite(.serialized)
struct FilePathiCloudCacheTests {
    private func withProvider(_ provider: @escaping () -> URL?, body: () -> Void) {
        let original = FilePath.ubiquityContainerProvider
        FilePath.ubiquityContainerProvider = provider
        FilePath.invalidateiCloudUrlCache()
        body()
        FilePath.ubiquityContainerProvider = original
        FilePath.invalidateiCloudUrlCache()
    }

    // A container appearing after a nil resolution must not flip the storage
    // location mid-session; only an explicit invalidation re-resolves
    @Test func iCloudUrl_cachesNilResolutionUntilInvalidated() {
        withProvider({ nil }) {
            #expect(FilePath.iCloudUrl == nil)

            FilePath.ubiquityContainerProvider = { URL(fileURLWithPath: "/container") }
            #expect(FilePath.iCloudUrl == nil)

            FilePath.invalidateiCloudUrlCache()
            #expect(FilePath.iCloudUrl?.path == "/container/Documents")
        }
    }

    // The observer callback fires only when re-resolution actually moves the location
    @Test func refreshReportingLocationChange_reportsOnlyActualMoves() {
        withProvider({ nil }) {
            // Nothing resolved yet: nothing to report
            #expect(!FilePath.refreshReportingLocationChange())

            #expect(FilePath.iCloudUrl == nil)
            #expect(!FilePath.refreshReportingLocationChange())

            FilePath.ubiquityContainerProvider = { URL(fileURLWithPath: "/container") }
            #expect(FilePath.refreshReportingLocationChange())
            #expect(!FilePath.refreshReportingLocationChange())
        }
    }
}
