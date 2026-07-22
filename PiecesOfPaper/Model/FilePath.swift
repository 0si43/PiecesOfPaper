import Foundation

enum FilePath {
    static var savingUrl: URL? {
        isiCloudActive ? iCloudUrl : documentDirectoryUrl
    }

    static var isiCloudActive: Bool {
        PreferenceRepository().getEnablediCloud() && iCloudUrl != nil
    }

    // url(forUbiquityContainerIdentifier:) is slow and not meant for the main thread,
    // but it is called from computed properties all over the app. Resolve it once and reuse.
    private static var cachediCloudUrl: URL?
    static var iCloudUrl: URL? {
        if let cachediCloudUrl {
            return cachediCloudUrl
        }
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let documentsUrl = url.appendingPathComponent("Documents")
        cachediCloudUrl = documentsUrl
        return documentsUrl
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

    static func makeDirectoryIfNeeded() {
        guard let inboxUrl = FilePath.inboxUrl, let archivedUrl = FilePath.archivedUrl else { return }
        if !FileManager.default.fileExists(atPath: inboxUrl.path) {
            try? FileManager.default.createDirectory(at: inboxUrl, withIntermediateDirectories: false)
        }

        if !FileManager.default.fileExists(atPath: archivedUrl.path) {
            try? FileManager.default.createDirectory(at: archivedUrl, withIntermediateDirectories: false)
        }
    }
}
