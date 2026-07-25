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
            "Failed to load \(count) note(s). The file may be corrupted."
        case .downloadFailed(let count):
            "Failed to download \(count) note(s) from iCloud. Check your network connection and try again."
        case .saveFailed:
            "Failed to save the note."
        case .deleteFailed:
            "Failed to delete the note."
        case .moveFailed:
            "Failed to move the note."
        case .bulkMoveFailed(let count):
            "Failed to move \(count) note(s). They remain in place."
        }
    }

    static func openFailure(from error: Error, count: Int) -> NoteStoreError {
        if case NoteRepositoryError.fileNotDownloaded = error {
            return .downloadFailed(count: count)
        }
        return .openFailed(count: count)
    }
}
