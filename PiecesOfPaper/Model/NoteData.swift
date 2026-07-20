//
//  NoteData.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2026/07/18.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

struct NoteData: Identifiable, Equatable {
    var entity: NoteEntity
    let fileURL: URL

    var id: UUID { entity.id }

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
}

extension NoteData {
    static func createTestData(fileURL: URL? = nil) -> NoteData {
        guard let url = fileURL ?? FilePath.inboxUrl?
            .appendingPathComponent("test-\(UUID().uuidString).pop") else {
            fatalError()
        }

        return NoteData(entity: NoteEntity(drawing: PKDrawing()), fileURL: url)
    }
}
