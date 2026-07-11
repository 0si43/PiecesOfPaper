//
//  NoteDocument.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/23.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import PencilKit

final class NoteDocument: UIDocument, Identifiable {
    var entity: NoteEntity
    var id: UUID { entity.id }

    var isArchived: Bool {
        guard let archivedUrl = FilePath.archivedUrl else { return false }
        return fileURL.path.hasPrefix(archivedUrl.path)
    }

    override init(fileURL: URL) {
        self.entity = NoteEntity(drawing: PKDrawing())
        super.init(fileURL: fileURL)

        if self.documentState == .inConflict {
            resolveConflict(url: fileURL)
        }
    }

    init(fileURL: URL, entity: NoteEntity) {
        self.entity = entity
        super.init(fileURL: fileURL)
    }

    override func contents(forType typeName: String) throws -> Any {
        try PropertyListEncoder().encode(entity)
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let content = contents as? Data else {
            throw NoteDocumentError.invalidContents
        }
        entity = try PropertyListDecoder().decode(NoteEntity.self, from: content)
    }

    // The later is the winner
    private func resolveConflict(url: URL) {
        let currentVersion = NSFileVersion.currentVersionOfItem(at: url)
        do {
            try NSFileVersion.removeOtherVersionsOfItem(at: url)
        } catch {
            print("failed delete conflict files")
        }
        currentVersion?.isResolved = true
    }

    static func createTestData() -> NoteDocument {
        guard let url = URL(string: "file:///test") else {
            fatalError()
        }

        return NoteDocument(fileURL: url, entity: NoteEntity(drawing: PKDrawing()))
    }
}

enum NoteDocumentError: LocalizedError {
    case invalidContents

    var errorDescription: String? {
        "The note file is not in a readable format."
    }
}
