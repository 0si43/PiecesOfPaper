//
//  Canvas.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/29.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit
import LinkPresentation

struct Canvas: View {
    @ObservedObject var viewModel = CanvasViewModel()
    @State private var canvasView = PKCanvasView()
    @State var hideExceptPaper = true
    @State var isShowActivityView = false {
        didSet {
            if isShowActivityView == true {
                toolPicker.setVisible(false, forFirstResponder: canvasView)
            }
        }
    }
    
    @Environment(\.presentationMode) var presentationMode

    var delegateBridge: DelegateBridgeObject
    var toolPicker: PKToolPicker = PKToolPicker()
    var activityViewController: UIActivityViewControllerWrapper {
        let drawing = canvasView.drawing
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        trait.performAsCurrent {
            image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
        }
        
        return UIActivityViewControllerWrapper(activityItems: [image, delegateBridge])
    }
    
    var tap: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                hideExceptPaper.toggle()
                toolPicker.addObserver(canvasView)
                toolPicker.setVisible(!hideExceptPaper, forFirstResponder: canvasView)
                canvasView.becomeFirstResponder()
            }
    }
    
    init(drawing: PKDrawing) {
        delegateBridge = DelegateBridgeObject(toolPicker: toolPicker)
        delegateBridge.canvas = self
        canvasView.delegate = delegateBridge
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
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button(action : delete){
                    Image(systemName: "trash").foregroundColor(.red)
                }
            )
            .toolbar {
                ToolbarItemGroup {
                    Button(action: { isShowActivityView.toggle() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: close) {
                        Text("Done")
                    }
                }
            }
            .sheet(isPresented: $isShowActivityView,
                   onDismiss: { toolPicker.setVisible(true, forFirstResponder: canvasView) }) {
                activityViewController
            }
    }
    
    private func delete() {
        // if autosave {
        //   delete()
        // ↓ is this equaled just do nothing?
        // } else {
        //    if isNoteNew {
        //      not save
        //    } else {
        //      discard change
        //    }
        // }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func close() {
        // if !autosave { save action }
        presentationMode.wrappedValue.dismiss()
    }
}


// MARK: - PKToolPickerObserver
///  This class conform some protocol, becaluse SwfitUI Views cannot conform PencilKit delegates
class DelegateBridgeObject: NSObject, PKToolPickerObserver {
    let toolPicker: PKToolPicker
    private let defaultTool = PKInkingTool(.pen, color: .black, width: 1)
    private var previousTool: PKTool!
    private var currentTool: PKTool!
    var canvas: Canvas!
    
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
        case .showColorPalette: canvas.hideExceptPaper.toggle()
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
        canvas.viewModel.appendDrawing(drawing: canvasView.drawing)
    }
}

// MARK: - UIActivityItemSource
extension DelegateBridgeObject: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return nil
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Share your note"
        return metadata
    }
}

// MARK: - PreviewProvider
struct Canvas_Previews: PreviewProvider {
    static var previews: some View {
        Canvas(drawing: PKDrawing())
    }
}
