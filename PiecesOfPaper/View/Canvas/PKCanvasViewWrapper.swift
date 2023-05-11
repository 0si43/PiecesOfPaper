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
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    private let saveAction: (PKDrawing) -> Void
    private var defaultTool = PKInkingTool(.pen, color: .black, width: 1)
    private var previousTool: PKTool
    private var currentTool: PKTool

    init(canvasView: Binding<PKCanvasView>, toolPicker: Binding<PKToolPicker>,
         saveAction: @escaping (PKDrawing) -> Void) {
        self._canvasView = canvasView
        self._toolPicker = toolPicker
        self.saveAction = saveAction
        self.previousTool = defaultTool
        self.currentTool = defaultTool
        self.canvasView.maximumZoomScale = 8.0
        initialContentSize()
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
        canvasView.drawingPolicy =
            UIDevice.current.userInterfaceIdiom == .pad
            ? .pencilOnly
            : .anyInput
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
        // ToolPickerが表示されているときは標準で動作する
        // カラーパレット出すアクションはないので、かわりにToolPickerを表示する
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
