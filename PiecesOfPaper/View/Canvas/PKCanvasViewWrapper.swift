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
    private let canvasView = PKCanvasView()
    @Binding var showToolPicker: Bool
    let saveAction: (PKDrawing) -> Void

    init(drawing: PKDrawing?, showToolPicker: Binding<Bool>,
         saveAction: @escaping (PKDrawing) -> Void) {
        self._showToolPicker = showToolPicker
        self.saveAction = saveAction
        canvasView.maximumZoomScale = 8.0
        if let drawing = drawing {
            self.canvasView.drawing = drawing
            initialContentSize()
        }
    }

    private var isDrawingWiderThanWindow: Bool {
        UIScreen.main.bounds.width < canvasView.drawing.bounds.maxX
    }

    private var isDrawingHigherThanWindow: Bool {
        UIScreen.main.bounds.height < canvasView.drawing.bounds.maxY
    }

    private func initialContentSize() {
        guard !canvasView.drawing.bounds.isNull else { return }

        if isDrawingWiderThanWindow, isDrawingHigherThanWindow {
            canvasView.contentSize = .init(width: canvasView.drawing.bounds.maxX,
                                           height: canvasView.drawing.bounds.maxY)
        } else if isDrawingWiderThanWindow, !isDrawingHigherThanWindow {
            canvasView.contentSize = .init(width: canvasView.drawing.bounds.maxX,
                                           height: UIScreen.main.bounds.height)
        } else if !isDrawingWiderThanWindow, isDrawingHigherThanWindow {
            canvasView.contentSize = .init(width: UIScreen.main.bounds.width,
                                           height: canvasView.drawing.bounds.maxY)
        }

        canvasView.contentOffset = .zero
    }

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.toolPicker.setVisible(showToolPicker, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: PKCanvasViewWrapper
        let toolPicker = PKToolPicker()
        private let defaultTool = PKInkingTool(.pen, color: .black, width: 1)
        private var previousTool: PKTool!
        private var currentTool: PKTool!
        init(_ canvasViewWrapper: PKCanvasViewWrapper) {
            self.parent = canvasViewWrapper

            toolPicker.selectedTool = defaultTool
            self.previousTool = defaultTool
            self.currentTool = defaultTool
            super.init()

            setToolPicker()
            setPencilInteraction()
        }

        private func setToolPicker() {
            toolPicker.showsDrawingPolicyControls = false
            toolPicker.addObserver(self)
            toolPicker.addObserver(parent.canvasView)
            toolPicker.setVisible(false, forFirstResponder: parent.canvasView)
            parent.canvasView.becomeFirstResponder()
        }

        private func setPencilInteraction() {
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
        previousTool = currentTool
        currentTool = toolPicker.selectedTool
    }
}

// MARK: - UIPencilInteractionDelegate
extension PKCanvasViewWrapper.Coordinator: UIPencilInteractionDelegate {
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        guard !toolPicker.isVisible else { return }
        let action = UIPencilInteraction.preferredTapAction
        switch action {
        case .switchPrevious:   switchPreviousTool()
        case .switchEraser:     switchEraser()
        case .showColorPalette: parent.showToolPicker.toggle()
        case .ignore:           return
        default:                return
        }
    }

    private func switchPreviousTool() {
        toolPicker.selectedTool = previousTool
    }

    private func switchEraser() {
        if currentTool is PKEraserTool {
            toolPicker.selectedTool = previousTool
        } else {
            toolPicker.selectedTool = PKEraserTool(.vector)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension PKCanvasViewWrapper.Coordinator: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        parent.canvasView
    }
}

 struct PKCanvasViewWrapper_Previews: PreviewProvider {
    @State static var drawing = PKDrawing()
    @State static var showToolPicker = false

    static var previews: some View {
        PKCanvasViewWrapper(drawing: drawing,
                            showToolPicker: $showToolPicker,
                            saveAction: { _ in })
    }
 }
