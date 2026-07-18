//
//  NoteDocument.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/23.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import PencilKit

final class NoteDocument: UIDocument {
    var entity: NoteEntity
    private var stateObserver: NSObjectProtocol?

    override init(fileURL: URL) {
        self.entity = NoteEntity(drawing: PKDrawing())
        super.init(fileURL: fileURL)
        observeStateChange()
    }

    init(fileURL: URL, entity: NoteEntity) {
        self.entity = entity
        super.init(fileURL: fileURL)
        observeStateChange()
    }

    deinit {
        if let stateObserver {
            NotificationCenter.default.removeObserver(stateObserver)
        }
    }

    // Conflict state is populated asynchronously after open(), never at init time,
    // so it has to be watched through stateChangedNotification.
    private func observeStateChange() {
        stateObserver = NotificationCenter.default.addObserver(
            forName: UIDocument.stateChangedNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.resolveConflictIfNeeded()
        }
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
    private func resolveConflictIfNeeded() {
        guard documentState.contains(.inConflict) else { return }
        do {
            try NSFileVersion.removeOtherVersionsOfItem(at: fileURL)
            NSFileVersion.currentVersionOfItem(at: fileURL)?.isResolved = true
        } catch {
            print("failed to delete conflict versions: ", error.localizedDescription)
        }
    }

}

enum NoteDocumentError: LocalizedError {
    case invalidContents

    var errorDescription: String? {
        "The note file is not in a readable format."
    }
}
