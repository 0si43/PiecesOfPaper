import Foundation
import PencilKit

struct NoteData: Identifiable, Equatable {
    var entity: NoteEntity
    let fileURL: URL

    var id: UUID { entity.id }

    /// Metadata-cache key; see NoteIndexEntry.fileName
    var fileName: String { fileURL.lastPathComponent }

    var isArchived: Bool {
        isUnder(FilePath.archivedUrl)
    }

    var isInInbox: Bool {
        isUnder(FilePath.inboxUrl)
    }

    // Compare resolved paths: URLs delivered by the Files app carry the
    // /private symlink prefix that FilePath's URLs lack. The separator suffix
    // keeps sibling directories like "InboxFolder2" from matching
    private func isUnder(_ directoryUrl: URL?) -> Bool {
        guard let directoryUrl else { return false }
        return fileURL.resolvingSymlinksInPath().path
            .hasPrefix(directoryUrl.resolvingSymlinksInPath().path + "/")
    }

    /// Directory membership by folder name alone, for notes whose absolute
    /// location no longer matches the current container — the storage location
    /// can change between minting the note URL and saving it (issue #225).
    var fallbackDirectory: NoteDirectory? {
        switch fileURL.deletingLastPathComponent().lastPathComponent {
        case FilePath.inboxDirectoryName: .inbox
        case FilePath.archivedDirectoryName: .archived
        default: nil
        }
    }
}

#if DEBUG
extension NoteData {
    static func createTestData(fileURL: URL? = nil) -> NoteData {
        guard let url = fileURL ?? FilePath.inboxUrl?
            .appendingPathComponent("test-\(UUID().uuidString).pop") else {
            fatalError()
        }

        return NoteData(entity: NoteEntity(drawing: PKDrawing()), fileURL: url)
    }
}
#endif
