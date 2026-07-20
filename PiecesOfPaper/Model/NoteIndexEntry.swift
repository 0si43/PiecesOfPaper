import Foundation

/// Listing metadata learned from a document open. Valid while its updatedDate
/// still matches the index entry's, i.e. the file on disk has not changed
/// since the open.
struct NoteMetadata: Equatable {
    let id: UUID
    var tags: [TagEntity]
    var updatedDate: Date
}

/// A note's listing metadata, built from file enumeration alone — no document open.
struct NoteIndexEntry: Identifiable, Equatable {
    let fileURL: URL
    let createdDate: Date
    let updatedDate: Date

    // The entity UUID is unknown until the document is opened, so list identity
    // is the file URL, which is unique on disk.
    var id: URL { fileURL }

    // Same resolved-path comparison as NoteData.isUnder: metadata-query URLs
    // can carry the /private symlink prefix that FilePath's URLs lack
    var isArchived: Bool {
        guard let archivedUrl = FilePath.archivedUrl else { return false }
        return fileURL.resolvingSymlinksInPath().path
            .hasPrefix(archivedUrl.resolvingSymlinksInPath().path + "/")
    }

    init(fileURL: URL, creationDate: Date?, contentModificationDate: Date?) {
        self.fileURL = fileURL
        let parsedDate = FilePath.parseTimestamp(fromFileName: fileURL.lastPathComponent)
        let updatedDate = contentModificationDate ?? parsedDate ?? creationDate ?? .distantPast
        self.createdDate = parsedDate ?? creationDate ?? updatedDate
        self.updatedDate = updatedDate
    }

    init(fileURL: URL, createdDate: Date, updatedDate: Date) {
        self.fileURL = fileURL
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }

    func moved(to fileURL: URL) -> NoteIndexEntry {
        NoteIndexEntry(fileURL: fileURL, createdDate: createdDate, updatedDate: updatedDate)
    }
}
