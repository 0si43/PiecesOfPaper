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
    @Binding var noteDocuments: [NoteDocument]
    let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)
    
    var body: some View {
        LazyVGrid(columns: [gridItem], spacing: 60.0) {
            ForEach((0..<noteDocuments.count), id: \.self) { index in
                Button(action: { open(noteDocument: noteDocuments[index]) }) {
                    Image(uiImage: noteDocuments[index].drawing.image(from: noteDocuments[index].drawing.bounds, scale: 1.0))
                        .resizable()
                        .frame(width: 250.0, height: 190.0)
                        .scaledToFit()
                        .background(Color(UIColor.secondarySystemBackground))
                        .shadow(radius: 5.0)
                }
                .contextMenu {
                    Button(action: { print("temp") }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    if #available(iOS 15.0, *) {
                        Button(role: .destructive) {
                            print("temp")
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } else {
                        Button(action: { print("temp") }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    Button(action: { print("temp") }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    func open(noteDocument: NoteDocument) {
        Router.shared.openCanvas(noteDocument: noteDocument)
    }
}

//struct NotesGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        NotesGrid()
//    }
//}
