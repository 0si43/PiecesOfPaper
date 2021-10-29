//
//  Canvas.swift
//  PiecesOfPaper
//
//  Created by nakajima on 2021/10/29.
//  Copyright © 2021 Tsuyoshi nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct PKCanvasViewWrapper: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 1)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) { }
}

struct PKCanvasViewWrapper_Previews: PreviewProvider {
    @State static var canvas = PKCanvasView()
    
    static var previews: some View {
        PKCanvasViewWrapper(canvasView: $canvas)
    }
}
