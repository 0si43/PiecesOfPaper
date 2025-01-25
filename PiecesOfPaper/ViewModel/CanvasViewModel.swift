//
//  CanvasViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

final class CanvasViewModel: ObservableObject {
    private var originalDocument: NoteDocument
    private(set) var document: NoteDocument
    @Published var showDrawingInformation = false

    var canReviewRequest: Bool {
        guard let inboxUrl = FilePath.inboxUrl,
              let inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: inboxUrl.path) else {
                  return false
              }
        return inboxFileNames.count >= 5
    }

    init(path: URL) {
        self.document = NoteDocument(fileURL: path, entity: NoteEntity(drawing: PKDrawing()))
        self.originalDocument = self.document
    }

    init(noteDocument: NoteDocument) {
        self.document = noteDocument
        self.originalDocument = self.document
    }

    func save() {
        save(drawing: document.entity.drawing)
    }

    func save(drawing: PKDrawing) {
        document.entity.drawing = drawing
        document.entity.updatedDate = Date()

        if FileManager.default.fileExists(atPath: document.fileURL.path) {
            document.save(to: document.fileURL, for: .forOverwriting)
        } else {
            document.save(to: document.fileURL, for: .forCreating)
        }
    }
}
