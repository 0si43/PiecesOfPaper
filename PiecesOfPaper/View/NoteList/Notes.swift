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
    var actionButton: Alert.Button {
        .destructive(
            Text(viewModel.isTargetDirectoryArchived ?  "Unarchived" : "Archived"),
            action: { viewModel.isTargetDirectoryArchived ? viewModel.allUnarchive() : viewModel.allArchive() }
        )
    }
    var cancelButton: Alert.Button { .default(Text("Cancel")) }

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
                    NotesScrollViewReader(viewModel: viewModel)
                }
            }

        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { viewModel.toggleArchiveOrUnarchiveAlert() }) {
                    Image(systemName: viewModel.isTargetDirectoryArchived ? "tray.circle" : "archivebox.circle")
                }
                Button(action: viewModel.toggleIsListConditionPopover ) { Image(systemName: "line.3.horizontal.decrease.circle") }
                Button(action: viewModel.update) { Image(systemName: "arrow.triangle.2.circlepath") }
                    .disabled(!viewModel.isLoaded)
                Button(action: new) { Image(systemName: "plus.circle") }
            }
        }
        .sheet(isPresented: $viewModel.isListConditionSheet) {
            NavigationView {
                ListConditionSetting(listCondition: $viewModel.listCondition)
            }
        }
        .alert(isPresented: $viewModel.showArchiveAlert) { () -> Alert in
            Alert(title: Text("""
                            Are you sure you want to \(viewModel.isTargetDirectoryArchived ? "unarchived" : "archived") \(viewModel.publishedNoteDocuments.count) notes ?
                            """),
                  primaryButton: actionButton,
                  secondaryButton: cancelButton)
        }
    }

    func new() {
        CanvasRouter.shared.openNewCanvas()
    }
}

struct Notes_Previews: PreviewProvider {
    static var previews: some View {
        Notes(viewModel: NotesViewModel(targetDirectory: .inbox))
    }
}
