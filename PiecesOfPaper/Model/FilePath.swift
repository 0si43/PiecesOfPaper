import Foundation
import os

enum FilePath {
    static var savingUrl: URL? {
        isiCloudActive ? iCloudUrl : documentDirectoryUrl
    }

    static var isiCloudActive: Bool {
        CloudAvailability.determine(enablediCloud: PreferenceRepository().getEnablediCloud(),
                                    hasAccount: FileManager.default.ubiquityIdentityToken != nil,
                                    containerUrl: iCloudUrl) == .available
    }

    // url(forUbiquityContainerIdentifier:) is slow and not meant for the main thread,
    // but it is called from computed properties all over the app. Resolve it once and reuse.
    // The absent result is cached too (.some(nil)), so the storage mode cannot flip
    // between two FilePath accesses inside one operation; revalidateiCloudUrl() is
    // the only way availability changes are picked up mid-session.
    private static var resolvediCloudUrl: URL??
    static var iCloudUrl: URL? {
        if let resolved = resolvediCloudUrl {
            return resolved
        }
        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
        resolvediCloudUrl = .some(url)
        return url
    }

    @MainActor
    static func revalidateiCloudUrl() async {
        let url = await Task.detached {
            FileManager.default.url(forUbiquityContainerIdentifier: nil)?
                .appendingPathComponent("Documents")
        }.value
        resolvediCloudUrl = .some(url)
    }

    static var documentDirectoryUrl: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    // avoided to conflict the name of "Documents/Inbox/"
    static var inboxUrl: URL? {
        savingUrl?.appendingPathComponent("InboxFolder")
    }

    static var archivedUrl: URL? {
        savingUrl?.appendingPathComponent("Archived")
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
