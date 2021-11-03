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
            Spacer(minLength: 30.0)
            LazyVGrid(columns: [gridItem], spacing: 60.0) {
                ForEach((0..<drawings.count), id: \.self) { index in
                    NavigationLink(destination: Canvas(drawing: drawings[index])) {
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
        .padding([.leading, .trailing])
        .navigationBarItems(trailing:
            Button(action : new){
                Image(systemName: "plus")
            }
        )
    }
    
    func new() {
        print("temp")
    }
}

struct NotesGrid_Previews: PreviewProvider {
    static var previews: some View {
        NotesGrid()
    }
}
