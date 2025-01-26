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
    }

    init(noteDocument: NoteDocument) {
        self.document = noteDocument
    }

    func save() {
        document.entity.updatedDate = Date()
        writeFile(document: document)
    }

    func save(drawing: PKDrawing) {
        guard document.entity.drawing != drawing else { return }
        document.entity.drawing = drawing
        document.entity.updatedDate = Date()
        writeFile(document: document)

    }

    private func writeFile(document: NoteDocument) {
        if FileManager.default.fileExists(atPath: document.fileURL.path) {
            document.save(to: document.fileURL, for: .forOverwriting)
        } else {
            document.save(to: document.fileURL, for: .forCreating)
        }
    }
}
