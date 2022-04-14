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
    let saveAction: (PKDrawing) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 1)
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: PKCanvasViewWrapper
        init(_ canvasViewWrapper: PKCanvasViewWrapper) {
            self.parent = canvasViewWrapper
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

// struct PKCanvasViewWrapper_Previews: PreviewProvider {
//    @State static var canvas = PKCanvasView()
//
//    static var previews: some View {
//        PKCanvasViewWrapper(canvasView: $canvas)
//    }
// }
