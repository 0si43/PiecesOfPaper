//
//  NoteView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct NoteView: View {
    private(set) var document: NoteDocument
    @State private var showCanvasView = false
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    private var image: UIImage {
        document.entity.drawing.image(from: document.entity.drawing.bounds, scale: 1.0)
    }

    var body: some View {
        Button(action: {
            showCanvasView = true
        }, label: {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 190)
                .background(Color(UIColor.secondarySystemBackground))
                .shadow(radius: 5)
        })
        .fullScreenCover(isPresented: $showCanvasView) {
            NavigationView {
                CanvasView(canvasViewModel: CanvasViewModel(noteDocument: document))
            }
        }
    }
}

#Preview {
    NoteView(document: NoteDocument.createTestData())
}
