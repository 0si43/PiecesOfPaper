import UIKit
import os

enum FilePath {
    static var savingUrl: URL? {
        isiCloudActive ? iCloudUrl : documentDirectoryUrl
    }

    static var isiCloudActive: Bool {
        PreferenceRepository().getEnablediCloud() && iCloudUrl != nil
    }

    // Seam for tests; production resolves the real ubiquity container.
    static var ubiquityContainerProvider: () -> URL? = {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)
    }

    // url(forUbiquityContainerIdentifier:) is slow and not meant for the main thread,
    // but it is called from computed properties all over the app. Resolve it once and reuse.
    // The nil outcome is cached too: retrying a late-resolving container would flip
    // savingUrl from local to iCloud mid-session, stranding just-saved notes outside
    // both listed directories (issue #225). Re-resolution only happens through
    // invalidateiCloudUrlCache().
    private static var cachediCloudResolution: URL??
    static var iCloudUrl: URL? {
        if let resolution = cachediCloudResolution {
            return resolution
        }
        let documentsUrl = ubiquityContainerProvider()?.appendingPathComponent("Documents")
        cachediCloudResolution = documentsUrl
        return documentsUrl
    }

    static func invalidateiCloudUrlCache() {
        cachediCloudResolution = nil
    }

    private static var ubiquityObservers: [NSObjectProtocol] = []

    /// Re-resolves the container when the iCloud identity may have changed
    /// (account switch, or any change made while the app was backgrounded) and
    /// reports only actual location changes so the caller can re-fetch.
    static func startObservingUbiquityChanges(onLocationChanged: @escaping () -> Void) {
        guard ubiquityObservers.isEmpty else { return }
        let names: [Notification.Name] = [
            .NSUbiquityIdentityDidChange,
            UIApplication.willEnterForegroundNotification
        ]
        ubiquityObservers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                if refreshReportingLocationChange() {
                    onLocationChanged()
                }
            }
        }
    }

    /// Re-resolves the container and reports whether the storage location
    /// actually moved. A never-resolved cache has no dependents yet, so there
    /// is nothing to report; the next iCloudUrl access resolves fresh.
    static func refreshReportingLocationChange() -> Bool {
        guard let previous = cachediCloudResolution else { return false }
        invalidateiCloudUrlCache()
        return iCloudUrl != previous
    }

    static var documentDirectoryUrl: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    // "InboxFolder", not "Inbox": avoided to conflict the name of "Documents/Inbox/"
    static let inboxDirectoryName = "InboxFolder"
    static let archivedDirectoryName = "Archived"

    static var inboxUrl: URL? {
        savingUrl?.appendingPathComponent(inboxDirectoryName)
    }

    static var archivedUrl: URL? {
        savingUrl?.appendingPathComponent(archivedDirectoryName)
    }

    static var libraryUrl: URL? {
        savingUrl?.appendingPathComponent("Library")
    }

    static let noteFileExtension = "pop"
    static let legacyNoteFileExtension = "plist"

    // Shared by generation and parsing so historical filenames written with the
    // device's default locale/calendar stay parseable by the same configuration.
    private static let fileNameTimestampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ssSSSS"
        return dateFormatter
    }()

    static var fileName: String {
        fileNameTimestampFormatter.string(from: Date()) + "." + noteFileExtension
    }

    static func parseTimestamp(fromFileName name: String) -> Date? {
        let stem = (name as NSString).deletingPathExtension
        return fileNameTimestampFormatter.date(from: stem)
    }

    static var tagListFileUrl: URL? {
        libraryUrl?.appendingPathComponent("taglist.json")
    }

    // Caches, not savingUrl: the metadata cache is derived from the notes
    // themselves and must never sync. The storage mode is part of the name so
    // toggling iCloud does not read another library's entries.
    static var noteMetadataCacheFileUrl: URL? {
        let suffix = isiCloudActive ? "icloud" : "local"
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("note-metadata-cache-\(suffix).json")
    }

    static func makeDirectoryIfNeeded() {
        guard let inboxUrl = FilePath.inboxUrl, let archivedUrl = FilePath.archivedUrl else { return }
        if !FileManager.default.fileExists(atPath: inboxUrl.path) {
            createDirectory(at: inboxUrl)
        }

        if !FileManager.default.fileExists(atPath: archivedUrl.path) {
            createDirectory(at: archivedUrl)
        }
    }

    // Intermediate directories stay off: the parent is the system-provided
    // Documents directory, so a missing parent should surface in the log
    // instead of being silently created
    private static func createDirectory(at url: URL) {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        } catch {
            Logger.filePath.error(
                "Failed to create directory at \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
