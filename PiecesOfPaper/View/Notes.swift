//
//  NotesGrid.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct Notes: View {
    @ObservedObject var viewModel: NotesViewModel
    
    init(viewModel: NotesViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        if !viewModel.isLoaded {
            ProgressView()
                .onAppear {
                    viewModel.fetch()
                }
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    Spacer(minLength: 30.0)
                    NotesGrid(noteDocuments: $viewModel.publishedNoteDocuments)
                }
                .padding([.leading, .trailing])
                .navigationBarItems(trailing:
                    Button(action: new){
                        Image(systemName: "plus")
                    }
                )
                .navigationBarTitleDisplayMode(.inline)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: { viewModel.update() }) {
                                Image(systemName: "plus")
                            }
                            Spacer()
                            ScrollButton(action: { scrollToBottom(proxy: proxy) },
                                         image: Image(systemName: "arrow.down.circle"))
                        }
                    }
                )
            }
        }
    }
    
    func new() {
        Router.shared.openNewCanvas()
    }
    
    func scrollToBottom(proxy: ScrollViewProxy) {
        proxy.scrollTo(viewModel.publishedNoteDocuments.count - 1, anchor: .bottom)
    }
}

struct Notes_Previews: PreviewProvider {
    static var previews: some View {
        Notes(viewModel: NotesViewModel(targetDirectory: .inbox))
    }
}
