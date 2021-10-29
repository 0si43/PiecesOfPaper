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
    
    var body: some View {
        PKCanvasViewWrapper(canvasView: $canvasView)
    }
}

struct Canvas_Previews: PreviewProvider {
    static var previews: some View {
        Canvas()
    }
}
