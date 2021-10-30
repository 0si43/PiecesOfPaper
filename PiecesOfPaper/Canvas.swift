//
//  Canvas.swift
//  PiecesOfPaper
//
//  Created by nakajima on 2021/10/29.
//  Copyright © 2021 Tsuyoshi nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct Canvas: View {
    @State private var canvasView = PKCanvasView()
    @State var hideExceptPaper = true
    var delegateBridge: DelegateBridgeObject
    // TODO: OS update
    var toolPicker: PKToolPicker = {
        if #available(iOS 14.0, *) {
            return PKToolPicker()
        } else {
            return PKToolPicker.shared(for: UIApplication.shared.windows.first!)!
        }
    }()
    
    var tap: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                hideExceptPaper.toggle()
                toolPicker.addObserver(canvasView)
                toolPicker.setVisible(!hideExceptPaper, forFirstResponder: canvasView)
                canvasView.becomeFirstResponder()
            }
    }
    
    init(drawing: PKDrawing = PKDrawing()) {
        delegateBridge = DelegateBridgeObject(toolPicker: toolPicker)
        canvasView.drawing = drawing
        addPencilInteraction()
    }
    
    private func addPencilInteraction() {
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = delegateBridge
        canvasView.addInteraction(pencilInteraction)
    }
    
    var body: some View {
        PKCanvasViewWrapper(canvasView: $canvasView)
            .gesture(tap)
            .statusBar(hidden: hideExceptPaper)
            .navigationBarHidden(hideExceptPaper)
    }
}

// MARK: - PKToolPickerObserver
///  This class conform some protocol, becaluse SwfitUI Views cannot conform PencilKit delegates
class DelegateBridgeObject: NSObject, PKToolPickerObserver {
    let toolPicker: PKToolPicker
    private let defaultTool = PKInkingTool(.pen, color: .black, width: 1)
    private var previousTool: PKTool!
    private var currentTool: PKTool!
    
    init(toolPicker: PKToolPicker) {
        self.toolPicker = toolPicker
        super.init()
        
        toolPicker.addObserver(self)
        toolPicker.selectedTool = defaultTool
        previousTool = defaultTool
        currentTool = defaultTool
    }
    
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        previousTool = currentTool
        currentTool = toolPicker.selectedTool
    }
}

// MARK: - UIPencilInteractionDelegate
extension DelegateBridgeObject: UIPencilInteractionDelegate {
    /// Double tap action on Appel Pencil when PKToolPicker is invisble(When it's visible, iOS handles its action)
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        guard !toolPicker.isVisible else { return }
        let action = UIPencilInteraction.preferredTapAction
        switch action {
        case .switchPrevious:   switchPreviousTool()
        case .switchEraser:     switchEraser()
//        case .showColorPalette: hideExceptPaper.toggle()
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

// MARK: - PKCanvasViewDelegate
extension DelegateBridgeObject: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // save action
    }
}


// MARK: - PreviewProvider
struct Canvas_Previews: PreviewProvider {
    static var previews: some View {
        Canvas()
    }
}
