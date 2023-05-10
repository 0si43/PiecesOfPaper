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
    private var cancelButton: Alert.Button { .default(Text("Cancel")) }
    private var actionButton: Alert.Button {
        .destructive(
            Text(viewModel.isTargetDirectoryArchived ?  "Unarchived" : "Archived"),
            action: { viewModel.isTargetDirectoryArchived ? viewModel.allUnarchive() : viewModel.allArchive() }
        )
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
                    NotesScrollViewReader(documents: viewModel.publishedNoteDocuments,
                                          parent: self)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showArchiveOrUnarchiveAlert() },
                       label: {
                            Image(systemName: viewModel.isTargetDirectoryArchived ? "tray.circle" : "archivebox.circle")
                        })
                Button(action: viewModel.toggleIsListConditionPopover,
                       label: { Image(systemName: "line.3.horizontal.decrease.circle") })
                Button(action: viewModel.update,
                       label: { Image(systemName: "arrow.triangle.2.circlepath") })
                    .disabled(!viewModel.isLoaded)
                Button(action: new) { Image(systemName: "plus.circle") }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showCanvas) {
            NavigationView {
                CanvasView(viewModel: CanvasViewModel())
            }
        }
        .sheet(isPresented: $viewModel.isListConditionSheet) {
            NavigationView {
                ListConditionSetting(listCondition: $viewModel.listCondition)
            }
        }
        .sheet(isPresented: $viewModel.showActivityView) {
            viewModel.activityViewController
        }
        .alert(isPresented: $viewModel.showArchiveAlert) { () -> Alert in
            Alert(title: Text(
                            "Are you sure you want to " +
                            "\(viewModel.isTargetDirectoryArchived ? "unarchived" : "archived")" + " " +
                            "\(viewModel.publishedNoteDocuments.count) notes?"
                            ),
                  primaryButton: cancelButton,
                  secondaryButton: actionButton)
        }
    }

    func new() {
        viewModel.showCanvas = true
    }
}

// MARK: - NotesGridParent

extension Notes: NotesGridParent {
    func getTagToNote(document: NoteDocument) -> [TagEntity] {
        viewModel.getTagToNote(document: document)
    }

    func duplicate(_ document: NoteDocument) {
        viewModel.duplicate(document)
    }

    func archive(_ document: NoteDocument) {
        viewModel.archive(document)
    }

    func unarchive(_ document: NoteDocument) {
        viewModel.unarchive(document)
    }

    func delete(_ document: NoteDocument) {
        viewModel.delete(document)
    }

    func showActivityView(_ document: NoteDocument) {
        viewModel.share(document)
    }
}

struct Notes_Previews: PreviewProvider {
    static var previews: some View {
        Notes(viewModel: NotesViewModel(targetDirectory: .inbox))
    }
}
