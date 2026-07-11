//
//  CanvasViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

@Observable
final class CanvasViewModel {
    private(set) var document: NoteDocument
    var showDrawingInformation = false
    private let noteRepository: NoteRepositoryProtocol

    var canReviewRequest: Bool {
        guard let inboxUrl = FilePath.inboxUrl,
              let inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: inboxUrl.path) else {
                  return false
              }
        return inboxFileNames.count >= 5
    }

    init(path: URL, noteRepository: NoteRepositoryProtocol = NoteRepository()) {
        self.document = NoteDocument(fileURL: path, entity: NoteEntity(drawing: PKDrawing()))
        self.noteRepository = noteRepository
    }

    init(noteDocument: NoteDocument, noteRepository: NoteRepositoryProtocol = NoteRepository()) {
        self.document = noteDocument
        self.noteRepository = noteRepository
    }

    func save() {
        document.entity.updatedDate = Date()
        noteRepository.save(document: document)
    }

    func save(drawing: PKDrawing) {
        guard document.entity.drawing != drawing else { return }
        document.entity.drawing = drawing
        document.entity.updatedDate = Date()
        noteRepository.save(document: document)
    }
}
