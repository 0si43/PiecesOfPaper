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

    var delegateBridge: CanvasDelegateBridgeObject
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
        delegateBridge = CanvasDelegateBridgeObject(toolPicker: toolPicker)
        delegateBridge.canvas = self
        canvasView.delegate = delegateBridge
        if !drawing.strokes.isEmpty {
            canvasView.drawing = drawing
        }
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

// MARK: - PreviewProvider
struct Canvas_Previews: PreviewProvider {
    static var previews: some View {
        Canvas(drawing: PKDrawing())
    }
}
