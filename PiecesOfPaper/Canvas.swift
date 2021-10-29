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
        canvasView.drawing = drawing
    }
    
    var body: some View {
        PKCanvasViewWrapper(canvasView: $canvasView)
            .gesture(tap)
            .statusBar(hidden: hideExceptPaper)
            .navigationBarHidden(hideExceptPaper)
    }
}

struct Canvas_Previews: PreviewProvider {
    static var previews: some View {
        Canvas()
    }
}
