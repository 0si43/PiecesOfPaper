//
//  NotesGrid.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct NotesGrid: View {
    @Binding var drawings: [PKDrawing]
    let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)
    
    var body: some View {
        LazyVGrid(columns: [gridItem], spacing: 60.0) {
            ForEach((0..<drawings.count), id: \.self) { index in
                Button(action: { open(drawing: drawings[index]) }) {
                    Image(uiImage: drawings[index].image(from: drawings[index].bounds, scale: 1.0))
                        .resizable()
                        .frame(width: 250.0, height: 190.0)
                        .scaledToFit()
                        .background(Color(UIColor.secondarySystemBackground))
                        .shadow(radius: 5.0)
                }
            }
        }
    }
    
    func open(drawing: PKDrawing) {
        Router.shared.openCanvas(drawing: drawing)
    }
}

//struct NotesGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        NotesGrid()
//    }
//}
