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
        let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: fileURL) ?? []
        do {
            if let winnerIndex = NoteConflictResolver.newestVersionIndex(
                currentModificationDate: NSFileVersion.currentVersionOfItem(at: fileURL)?.modificationDate,
                conflictModificationDates: conflictVersions.map(\.modificationDate)
            ) {
                try conflictVersions[winnerIndex].replaceItem(at: fileURL)
            }
            try NSFileVersion.removeOtherVersionsOfItem(at: fileURL)
            conflictVersions.forEach { $0.isResolved = true }
        } catch {
            print("failed to resolve conflict versions: ", error.localizedDescription)
        }
    }

}

enum NoteConflictResolver {
    /// Returns the index of the conflict version that should replace the current
    /// version, or nil when the current version is the newest (ties favor current,
    /// so no file replacement happens unless a strictly newer version exists).
    static func newestVersionIndex(currentModificationDate: Date?,
                                   conflictModificationDates: [Date?]) -> Int? {
        let currentDate = currentModificationDate ?? .distantPast
        var winner: (index: Int, date: Date)?
        for (index, date) in conflictModificationDates.enumerated() {
            let date = date ?? .distantPast
            if date > (winner?.date ?? currentDate) {
                winner = (index, date)
            }
        }
        return winner?.index
    }
}

enum NoteDocumentError: LocalizedError {
    case invalidContents

    var errorDescription: String? {
        "The note file is not in a readable format."
    }
}
