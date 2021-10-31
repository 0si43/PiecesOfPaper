//
//  NotesGrid.swift
//  PiecesOfPaper
//
//  Created by nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct NotesGrid: View {
    var drawings = [PKDrawing]()
    let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [gridItem], spacing: 80.0) {
                ForEach((0..<drawings.count), id: \.self) {
                    Image(uiImage: drawings[$0].image(from: drawings[$0].bounds, scale: 1.0))
                        .resizable()
                        .frame(width: 250.0, height: 180.0)
                        .scaledToFit()
                        .background(Color(UIColor.secondarySystemBackground))
                        .shadow(radius: 5.0)
                }
            }
        }
        .padding()
    }
}

struct NotesGrid_Previews: PreviewProvider {
    static var previews: some View {
        NotesGrid()
    }
}
