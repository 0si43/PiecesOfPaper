//
//  NotesScrollViewReader.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NotesScrollViewReader: View {
    @Binding var documents: [NoteDocument]
    var reloadAction: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Spacer(minLength: 30.0)
                NotesGrid(noteDocuments: $documents)
            }
            .padding([.leading, .trailing])
            .navigationBarItems(trailing:
                HStack {
                    Button(action: reloadAction) { Image(systemName: "arrow.triangle.2.circlepath") }
                    Button(action: new) { Image(systemName: "plus") }
                })
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ScrollButton(action: { scrollToBottom(proxy: proxy) },
                                     image: Image(systemName: "arrow.down.circle"))
                    }
                }
            )
        }
    }

    func new() {
        Router.shared.openNewCanvas()
    }

    func scrollToBottom(proxy: ScrollViewProxy) {
        proxy.scrollTo(documents.count - 1, anchor: .bottom)
    }
}

// struct NotesScrollViewReader_Previews: PreviewProvider {
//    static var previews: some View {
//        NotesScrollViewReader(documents: [NoteDocument()])
//    }
// }
