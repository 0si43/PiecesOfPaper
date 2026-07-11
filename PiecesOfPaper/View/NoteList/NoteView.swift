//
//  NoteView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct NoteView: View {
    private(set) var document: NoteDocument
    @State private var showCanvasView = false
    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: {
            showCanvasView = true
        }, label: {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.clear
                }
            }
            .frame(width: 250, height: 190)
            .background(Color(UIColor.secondarySystemBackground))
            .shadow(radius: 5)
        })
        .accessibilityLabel("Note")
        .task(id: document.entity.updatedDate) {
            thumbnail = await ThumbnailCache.shared.thumbnail(for: document)
        }
        .fullScreenCover(isPresented: $showCanvasView) {
            NavigationView {
                CanvasView(canvasViewModel: CanvasViewModel(noteDocument: document))
            }
        }
    }
}

#Preview {
    NoteView(document: NoteDocument.createTestData())
}
