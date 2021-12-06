//
//  NotesScrollViewReader.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NotesScrollViewReader: View {
    @EnvironmentObject var noteViewModel: NotesViewModel
    var noteDocuments: [NoteDocument] {
        noteViewModel.publishedNoteDocuments
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Spacer(minLength: 30.0)
                NotesGrid()
                    .environmentObject(noteViewModel)
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
        proxy.scrollTo(noteDocuments.count - 1, anchor: .bottom)
    }
}

// struct NotesScrollViewReader_Previews: PreviewProvider {
//    static var previews: some View {
//        NotesScrollViewReader(documents: [NoteDocument()])
//    }
// }
