import Foundation

enum NoteStoreError: LocalizedError {
    case openFailed(count: Int)
    case saveFailed
    case deleteFailed
    case moveFailed

    var errorDescription: String? {
        switch self {
        case .openFailed(let count):
            "Failed to load \(count) note(s). The files may be corrupted or not downloaded yet."
        case .saveFailed:
            "Failed to save the note."
        case .deleteFailed:
            "Failed to delete the note."
        case .moveFailed:
            "Failed to move the note."
        }
    }
}
