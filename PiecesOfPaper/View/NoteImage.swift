//
//  NoteImage.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteImage: View {
    var noteDocument: NoteDocument

    var body: some View {
        Button(action: { open(noteDocument: noteDocument) },
               label: {
                Image(uiImage: noteDocument.entity.drawing.image(from: noteDocument.entity.drawing.bounds, scale: 1.0))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250.0, height: 190.0)
                    .background(Color(UIColor.secondarySystemBackground))
                    .shadow(radius: 5.0)
        })
    }

    func open(noteDocument: NoteDocument) {
        Router.shared.openCanvas(noteDocument: noteDocument)
    }
}

// struct NoteImage_Previews: PreviewProvider {
//    static var previews: some View {
//        NoteImage()
//    }
// }
