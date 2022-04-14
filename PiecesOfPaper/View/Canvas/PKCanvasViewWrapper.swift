//
//  Canvas.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/29.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct PKCanvasViewWrapper: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var showToolPicker: Bool

    let saveAction: (PKDrawing) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.toolPicker.setVisible(showToolPicker, forFirstResponder: canvasView)
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

            self.previousTool = defaultTool
            self.currentTool = defaultTool
            toolPicker.selectedTool = defaultTool
            super.init()

            toolPicker.showsDrawingPolicyControls = false
            toolPicker.addObserver(self)
            toolPicker.addObserver(canvasViewWrapper.canvasView)
            toolPicker.setVisible(true, forFirstResponder: canvasViewWrapper.canvasView)

            let pencilInteraction = UIPencilInteraction()
            pencilInteraction.delegate = self
            canvasViewWrapper.canvasView.addInteraction(pencilInteraction)
        }
    }
}

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

extension PKCanvasViewWrapper.Coordinator: PKToolPickerObserver {
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        previousTool = currentTool
        currentTool = toolPicker.selectedTool
    }
}

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

// struct PKCanvasViewWrapper_Previews: PreviewProvider {
//    @State static var canvas = PKCanvasView()
//
//    static var previews: some View {
//        PKCanvasViewWrapper(canvasView: $canvas)
//    }
// }
