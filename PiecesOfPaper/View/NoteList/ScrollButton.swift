//
//  ScrollButton.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/23.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct ScrollButton: View {
    private(set) var action: () -> Void
    private(set) var image: Image

    var body: some View {
        Button(action: action) {
            image.resizable()
                .foregroundColor(Color.blue.opacity(0.3))
                .frame(width: 60.0, height: 60.0)
                .padding()
        }
    }
}

#Preview {
    ScrollButton(action: { print("test") }, image: Image(systemName: "arrow.down.circle"))
}
