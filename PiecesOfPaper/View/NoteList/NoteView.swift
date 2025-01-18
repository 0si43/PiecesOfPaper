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
    var document: NoteDocument
    @EnvironmentObject var canvasViewModel: CanvasViewModel
    @State var showCanvasView = false
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
                .frame(width: 250.0, height: 190.0)
                .background(Color(UIColor.secondarySystemBackground))
                .shadow(radius: 5.0)
        })
        .fullScreenCover(isPresented: $showCanvasView) {
            NavigationView {
                CanvasView(canvasViewModel: CanvasViewModel(noteDocument: document))
            }
        }
    }
}

 struct NoteImage_Previews: PreviewProvider {
     static var previews: some View {
         NoteView(document: NoteDocument.createTestData())
             .environmentObject(CanvasViewModel())
    }
 }
