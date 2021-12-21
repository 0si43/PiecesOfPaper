//
//  NoteImage.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteImage: View {
    @Binding var noteDocument: NoteDocument
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    private var image: UIImage {
        noteDocument.entity.drawing.image(from: noteDocument.entity.drawing.bounds, scale: 1.0)
    }

    var body: some View {
        Button(action: { open(noteDocument: noteDocument) },
               label: {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250.0, height: 190.0)
                    .background(Color(UIColor.secondarySystemBackground))
                    .shadow(radius: 5.0)
        })
    }

    func open(noteDocument: NoteDocument) {
        CanvasRouter.shared.openCanvas(noteDocument: noteDocument)
    }
}

// struct NoteImage_Previews: PreviewProvider {
//    static var previews: some View {
//        NoteImage()
//    }
// }
