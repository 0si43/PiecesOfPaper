//
//  NoteIndexEntry.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2026/07/20.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

/// A note's listing metadata, built from file enumeration alone — no document open.
struct NoteIndexEntry: Identifiable, Equatable {
    let fileURL: URL
    let createdDate: Date
    let updatedDate: Date

    // The entity UUID is unknown until the document is opened, so list identity
    // is the file URL, which is unique on disk.
    var id: URL { fileURL }

    var isArchived: Bool {
        guard let archivedUrl = FilePath.archivedUrl else { return false }
        return fileURL.path.hasPrefix(archivedUrl.path)
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
}
