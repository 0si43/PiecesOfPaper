//
//  NoteImage.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct NoteImage: View {
    var drawing: PKDrawing
    var action: () -> Void
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    private var image: UIImage {
        drawing.image(from: drawing.bounds, scale: 1.0)
    }

    var body: some View {
        Button(action: action,
               label: {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250.0, height: 190.0)
                    .background(Color(UIColor.secondarySystemBackground))
                    .shadow(radius: 5.0)
        })
    }
}

// struct NoteImage_Previews: PreviewProvider {
//    static var previews: some View {
//        NoteImage()
//    }
// }
