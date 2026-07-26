import Foundation

enum NoteStoreError: LocalizedError, Equatable {
    case openFailed(count: Int)
    case downloadFailed(count: Int)
    case saveFailed
    case deleteFailed
    case moveFailed
    case bulkMoveFailed(count: Int)

    var errorDescription: String? {
        switch self {
        case .openFailed(let count):
            count == 1
                ? "Failed to load the note. The file may be corrupted."
                : "Failed to load \(count) notes. The files may be corrupted."
        case .downloadFailed(let count):
            """
            Failed to download \(count == 1 ? "the note" : "\(count) notes") from iCloud. \
            Check your network connection and try again.
            """
        case .saveFailed:
            "Failed to save the note."
        case .deleteFailed:
            "Failed to delete the note."
        case .moveFailed:
            "Failed to move the note."
        case .bulkMoveFailed(let count):
            count == 1
                ? "Failed to move the note. It remains in place."
                : "Failed to move \(count) notes. They remain in place."
        }
    }

    static func openFailure(from error: Error, count: Int) -> NoteStoreError {
        if case NoteRepositoryError.fileNotDownloaded = error {
            return .downloadFailed(count: count)
        }
        return .openFailed(count: count)
    }
}
