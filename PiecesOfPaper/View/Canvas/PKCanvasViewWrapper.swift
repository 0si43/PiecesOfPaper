//
//  PKCanvasViewWrapper.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/29.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct PKCanvasViewWrapper: UIViewRepresentable {
    @Binding private var canvasView: PKCanvasView
    @Binding private var toolPicker: PKToolPicker
    private let saveAction: (PKDrawing) -> Void
    private var defaultTool = PKInkingTool(.pen, color: .black, width: 1)
    private var previousTool: PKTool
    private var currentTool: PKTool

    init(canvasView: Binding<PKCanvasView>,
         toolPicker: Binding<PKToolPicker>,
         saveAction: @escaping (PKDrawing) -> Void) {
        self._canvasView = canvasView
        self._toolPicker = toolPicker
        self.saveAction = saveAction
        self.previousTool = defaultTool
        self.currentTool = defaultTool
    }

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.maximumZoomScale = 8.0
        if UIDevice.current.userInterfaceIdiom == .pad {
            canvasView.drawingPolicy = .pencilOnly
        }
        toolPicker.showsDrawingPolicyControls = false
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
        toolPicker.selectedTool = defaultTool
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: PKCanvasViewWrapper
        init(_ canvasViewWrapper: PKCanvasViewWrapper) {
            self.parent = canvasViewWrapper
            super.init()
            canvasViewWrapper.canvasView.delegate = self
            canvasViewWrapper.toolPicker.addObserver(self)
            let pencilInteraction = UIPencilInteraction()
            pencilInteraction.delegate = self
            parent.canvasView.addInteraction(pencilInteraction)
        }
    }
}

// MARK: - PKCanvasViewDelegate
extension PKCanvasViewWrapper.Coordinator: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updateContentSizeIfNeeded(canvasView)

        guard UserPreference().enabledAutoSave else { return }
        parent.saveAction(canvasView.drawing)
    }

    private func updateContentSizeIfNeeded(_ canvasView: PKCanvasView) {
        guard !canvasView.drawing.bounds.isNull,
              UserPreference().enabledInfiniteScroll else { return }
        let drawingWidth = canvasView.drawing.bounds.maxX
        if canvasView.contentSize.width * 9 / 10 < drawingWidth {
            canvasView.contentSize.width += canvasView.frame.width
        }

        let drawingHeight = canvasView.drawing.bounds.maxY
        if canvasView.contentSize.height * 9 / 10 < drawingHeight {
            canvasView.contentSize.height += canvasView.frame.height
        }
    }

}

// MARK: - PKToolPickerObserver
extension PKCanvasViewWrapper.Coordinator: PKToolPickerObserver {
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        parent.previousTool = parent.currentTool
        parent.currentTool = toolPicker.selectedTool
    }
}

// MARK: - UIPencilInteractionDelegate
extension PKCanvasViewWrapper.Coordinator: UIPencilInteractionDelegate {
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        guard !parent.toolPicker.isVisible else { return }
        let action = UIPencilInteraction.preferredTapAction
        switch action {
        case .switchPrevious:   switchPreviousTool()
        case .switchEraser:     switchEraser()
        default:                showToolPicker()
        }
    }

    private func switchPreviousTool() {
        parent.toolPicker.selectedTool = parent.previousTool
    }

    private func switchEraser() {
        if parent.currentTool is PKEraserTool {
            parent.toolPicker.selectedTool = parent.previousTool
        } else {
            parent.toolPicker.selectedTool = PKEraserTool(.vector)
        }
    }

    private func showToolPicker() {
        parent.toolPicker.setVisible(!parent.toolPicker.isVisible, forFirstResponder: parent.canvasView)
        parent.canvasView.becomeFirstResponder()
    }
}

// MARK: - UIScrollViewDelegate
extension PKCanvasViewWrapper.Coordinator: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        parent.canvasView
    }
}

 struct PKCanvasViewWrapper_Previews: PreviewProvider {
    @State static var canvasView = PKCanvasView()
    @State static var toolPicker = PKToolPicker()

    static var previews: some View {
        PKCanvasViewWrapper(canvasView: $canvasView,
                            toolPicker: $toolPicker,
                            saveAction: { _ in })
    }
 }
