//
//  NotesGrid.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct Notes: View {
    @ObservedObject var viewModel: NotesViewModel

    init(viewModel: NotesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if !viewModel.isLoaded {
            ProgressView()
                .onAppear {
                    guard !viewModel.didFirstFetchRequest else { return }
                    viewModel.fetch()
                    viewModel.didFirstFetchRequest = true
                }
        } else {
            NotesScrollViewReader(documents: $viewModel.publishedNoteDocuments,
                                  reloadAction: viewModel.update)
        }
    }
}

struct Notes_Previews: PreviewProvider {
    static var previews: some View {
        Notes(viewModel: NotesViewModel(targetDirectory: .inbox))
    }
}
