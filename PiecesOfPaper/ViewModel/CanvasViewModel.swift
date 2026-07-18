//
//  CanvasViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

@MainActor
@Observable
final class CanvasViewModel {
    private(set) var note: NoteData
    var showDrawingInformation = false
    var showSaveFailedAlert = false
    var onPersisted: ((NoteData) -> Void)?
    private let noteRepository: NoteRepositoryProtocol

    var canReviewRequest: Bool {
        guard let inboxUrl = FilePath.inboxUrl,
              let inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: inboxUrl.path) else {
                  return false
              }
        return inboxFileNames.count >= 5
    }

    init(newNoteAt path: URL, noteRepository: NoteRepositoryProtocol = NoteRepository()) {
        self.note = NoteData(entity: NoteEntity(drawing: PKDrawing()), fileURL: path)
        self.noteRepository = noteRepository
    }

    init(note: NoteData, noteRepository: NoteRepositoryProtocol = NoteRepository()) {
        self.note = note
        self.noteRepository = noteRepository
    }

    func hasUnsavedChanges(comparedTo drawing: PKDrawing) -> Bool {
        drawing != note.entity.drawing
    }

    func save(drawing: PKDrawing, completion: ((Bool) -> Void)? = nil) {
        guard hasUnsavedChanges(comparedTo: drawing) else {
            completion?(true)
            return
        }
        note.entity.drawing = drawing
        note.entity.updatedDate = Date()
        let saved = note
        noteRepository.save(saved.entity, to: saved.fileURL) { [weak self] success in
            if success {
                self?.onPersisted?(saved)
            } else {
                self?.showSaveFailedAlert = true
            }
            completion?(success)
        }
    }
}
