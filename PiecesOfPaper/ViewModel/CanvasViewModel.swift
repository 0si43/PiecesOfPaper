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
    private(set) var document: NoteDocument?
    @Published var showDrawingInformation = false
    @Published var showTagList = false

    var canReviewRequest: Bool {
        guard let inboxUrl = FilePath.inboxUrl,
              let inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: inboxUrl.path) else {
                  return false
              }
        return inboxFileNames.count >= 5
    }

    init() {
        if let path = FilePath.inboxUrl?.appendingPathComponent(FilePath.fileName) {
            self.document = NoteDocument(fileURL: path, entity: NoteEntity(drawing: PKDrawing()))
        }
    }

    init(noteDocument: NoteDocument) {
        self.document = noteDocument
    }

    func save() {
        guard let document else { return }
        save(drawing: document.entity.drawing)
    }

    func save(drawing: PKDrawing) {
        guard let document else { return }
        document.entity.drawing = drawing
        document.entity.updatedDate = Date()

        if FileManager.default.fileExists(atPath: document.fileURL.path) {
            document.save(to: document.fileURL, for: .forOverwriting)
        } else {
            document.save(to: document.fileURL, for: .forCreating)
        }
    }

    func archive() {
        guard let archivedUrl = FilePath.archivedUrl, let document else { return }
        let toUrl = archivedUrl.appendingPathComponent(document.fileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: document.fileURL, to: toUrl)
        } catch {
            print("Could not archive: ", error.localizedDescription)
        }
    }
}
