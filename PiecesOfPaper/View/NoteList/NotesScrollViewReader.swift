//
//  NotesScrollViewReader.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NotesScrollViewReader: View {
    var documents: [NoteDocument]
    var parent: NotesGridParent

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Spacer(minLength: 30.0)
                NotesGrid(documents: documents, parent: parent)
            }
            .padding([.leading, .trailing])
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

    func scrollToBottom(proxy: ScrollViewProxy) {
        proxy.scrollTo(documents.endIndex - 1, anchor: .bottom)
    }
}

 struct NotesScrollViewReader_Previews: PreviewProvider {
     static var array = Array(repeating: NoteDocument.createTestData(), count: 9)
     static var parent = Notes(viewModel: NotesViewModel(targetDirectory: .inbox))
    static var previews: some View {
        NotesScrollViewReader(documents: array, parent: parent)
    }
 }
