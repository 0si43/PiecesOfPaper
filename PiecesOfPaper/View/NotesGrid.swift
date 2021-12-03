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
    @State var isShowActivityView = false
    @State var documentToShare: NoteDocument?
    @Binding var noteDocuments: [NoteDocument]
    let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)
    var activityViewController: UIActivityViewControllerWrapper? {
        guard let document = documentToShare else { return nil }
        let drawing = document.drawing
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        trait.performAsCurrent {
            image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
        }
        
        return UIActivityViewControllerWrapper(activityItems: [image])
    }
    
    var body: some View {
        LazyVGrid(columns: [gridItem], spacing: 60.0) {
            ForEach((0..<noteDocuments.count), id: \.self) { index in
                NoteImage(noteDocument: $noteDocuments[index])
                .contextMenu {
                    Button(action: {
                        duplicate(noteDocument: noteDocuments[index])
                    }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    if #available(iOS 15.0, *) {
                        Button(role: .destructive) {
                            delete(noteDocument: noteDocuments[index])
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } else {
                        Button(action: {
                            delete(noteDocument: noteDocuments[index])
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    Button(action: {
                        share(noteDocument: noteDocuments[index])
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $isShowActivityView) {
            activityViewController
        }
    }
    
    func duplicate(noteDocument: NoteDocument) {
        let newUrl = FilePath.iCloudURL.appendingPathComponent(FilePath.fileName)
        try? FileManager.default.copyItem(at: noteDocument.fileURL, to: newUrl)
    }
    
    func delete(noteDocument: NoteDocument) {
        try? FileManager.default.removeItem(at: noteDocument.fileURL)
    }
    
    func share(noteDocument: NoteDocument) {
        documentToShare = noteDocument
        isShowActivityView = true
    }
}

//struct NotesGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        NotesGrid()
//    }
//}
