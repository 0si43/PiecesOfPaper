import Foundation

enum NoteStoreError: LocalizedError, Equatable {
    case openFailed(count: Int)
    case saveFailed
    case deleteFailed
    case moveFailed
    case bulkMoveFailed(count: Int)

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
        case .bulkMoveFailed(let count):
            "Failed to move \(count) note(s). They remain in place."
        }
    }
}
