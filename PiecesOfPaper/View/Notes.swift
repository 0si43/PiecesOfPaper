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

    init(targetDirectory: NotesViewModel.TargetDirectory) {
        self.viewModel = NotesViewModel(targetDirectory: targetDirectory)
    }

    var body: some View {
        Group {
            if !viewModel.isLoaded {
                ProgressView()
                    .onAppear {
                        guard !viewModel.didFirstFetchRequest else { return }
                        viewModel.fetch()
                        viewModel.didFirstFetchRequest = true
                    }
            } else {
                if viewModel.publishedNoteDocuments.isEmpty {
                    Text("No Data")
                        .font(.largeTitle)
                } else {
                    NotesScrollViewReader()
                        .environmentObject(viewModel)
                }
            }

        }
        .navigationBarItems(trailing:
            HStack {
                Button(action: viewModel.toggleIsListConditionPopover ) { Image(systemName: "line.3.horizontal.decrease.circle")
                }
                Button(action: viewModel.update) { Image(systemName: "arrow.triangle.2.circlepath") }
                Button(action: new) { Image(systemName: "plus.circle") }
            })
        .sheet(isPresented: $viewModel.isListConditionSheet) {
            NavigationView {
                ListConditionSetting()
            }
        }
    }

    func new() {
        CanvasRouter.shared.openNewCanvas()
    }
}

struct Notes_Previews: PreviewProvider {
    static var previews: some View {
        Notes(targetDirectory: .inbox)
    }
}
