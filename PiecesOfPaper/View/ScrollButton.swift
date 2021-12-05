//
//  ScrollButton.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/23.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct ScrollButton: View {
    var action: () -> Void
    var image: Image

    var body: some View {
        Button(action: action) {
            image.resizable()
                .foregroundColor(Color.blue.opacity(0.3))
                .frame(width: 60.0, height: 60.0)
                .padding()
        }
    }
}

struct ScrollButton_Previews: PreviewProvider {
    static var previews: some View {
        let action = { print("test") }
        let image = Image(systemName: "arrow.down.circle")
        ScrollButton(action: action, image: image)
    }
}
