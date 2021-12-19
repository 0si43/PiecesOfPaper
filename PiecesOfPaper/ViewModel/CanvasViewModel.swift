//
//  CanvasViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

final class CanvasViewModel: ObservableObject, CanvasDelegateBridgeObjectDelegate {
    var document: NoteDocument? {
        didSet {
            if document == nil {
                createNewDocument()
            }

            canvasView.delegate = nil
            if let drawing = document?.entity.drawing {
                canvasView.drawing = drawing
                initialContentSize()
            }

            canvasView.delegate = delegateBridge
        }
    }

    var canvasView = PKCanvasView() {
        didSet {
            canvasView.delegate = delegateBridge
            delegateBridge.toolPicker.addObserver(canvasView)
            addPencilInteraction()
        }
    }

    @Published var hideExceptPaper = true
    @Published var showDrawingInformation = false
    @Published var showTagList = false
    @Published var showUnsavedAlert = false
    @Published var isShowActivityView = false {
        didSet {
            if isShowActivityView == true {
                delegateBridge.toolPicker.setVisible(false, forFirstResponder: canvasView)
            }
        }
    }

    private let delegateBridge = CanvasDelegateBridgeObject()

    var canReviewRequest: Bool {
        guard let inboxUrl = FilePath.inboxUrl,
              let inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: inboxUrl.path)  else { return false }
        return inboxFileNames.count >= 5
    }

    var hasSavedDocument = false

    var activityViewController: UIActivityViewControllerWrapper {
        let drawing = canvasView.drawing
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        trait.performAsCurrent {
            image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
        }

        return UIActivityViewControllerWrapper(activityItems: [image, delegateBridge])
    }

    init(noteDocument: NoteDocument? = nil) {
        self.document = noteDocument

        delegateBridge.delegate = self
        canvasView.delegate = delegateBridge
        delegateBridge.toolPicker.addObserver(canvasView)
        addPencilInteraction()
    }

    private func createNewDocument() {
        defer {
            hasSavedDocument = false
        }

        guard let inboxUrl = FilePath.inboxUrl else { return }
        let path = inboxUrl.appendingPathComponent(FilePath.fileName)
        document = NoteDocument(fileURL: path, entity: NoteEntity(drawing: PKDrawing()))
        canvasView = PKCanvasView()
    }

    private func addPencilInteraction() {
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = delegateBridge
        canvasView.addInteraction(pencilInteraction)
    }

    func initialContentSize() {
        guard !canvasView.drawing.bounds.isNull else { return }

        if canvasView.frame.width < canvasView.drawing.bounds.maxX {
            canvasView.contentSize.width = canvasView.drawing.bounds.maxX
        }

        if canvasView.frame.height < canvasView.drawing.bounds.maxY {
            canvasView.contentSize.height = canvasView.drawing.bounds.maxY
        }
    }

    func save(drawing: PKDrawing) {
        defer {
            hasSavedDocument = true
        }

        document?.entity.drawing = drawing
        document?.entity.updatedDate = Date()
        guard let document = document else { return }

        if FileManager.default.fileExists(atPath: document.fileURL.path) {
            document.save(to: document.fileURL, for: .forOverwriting)
        } else {
            document.save(to: document.fileURL, for: .forCreating)
        }
    }

    func archive() {
        guard let document = document,
              let archivedUrl = FilePath.archivedUrl else { return }
        let toUrl = archivedUrl.appendingPathComponent(document.fileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: document.fileURL, to: toUrl)
        } catch {
            print("Could not archive: ", error.localizedDescription)
        }
    }

    func setVisibleToolPicker(_ isVisible: Bool) {
        delegateBridge.toolPicker.setVisible(isVisible, forFirstResponder: canvasView)
    }
}
