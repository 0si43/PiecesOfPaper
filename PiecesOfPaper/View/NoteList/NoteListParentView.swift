//
//  NoteListParentView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteListParentView: View {
    @ObservedObject private var viewModel: NotesViewModel
    @EnvironmentObject private var canvasViewModel: CanvasViewModel
    @State private var showCanvasView = false
    @State private var showListConditionSettingView = false
    @State private var documentToShare: NoteDocument?
    @State private var documentToTag: NoteDocument?
    @State private var showArchiveAlert = false

    init(viewModel: NotesViewModel) {
        self.viewModel = viewModel
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
                    NoteScrollView(documents: viewModel.publishedNoteDocuments, parent: self)
                }
            }
        }
        .toolbar {
            toolbarItems
        }
        .fullScreenCover(isPresented: $showCanvasView) {
            NavigationView {
                CanvasView(canvasViewModel: CanvasViewModel())
            }
        }
        .sheet(isPresented: $showListConditionSettingView) {
            NavigationView {
                ListConditionSettingView(listCondition: $viewModel.listCondition)
            }
        }
        .sheet(item: $documentToShare) { document in
            activityViewController(document: document)
        }
        .sheet(item: $documentToTag) { document in
            AddTagView(viewModel: TagListToNoteViewModel(noteDocument: document))
        }
        .alert(isPresented: $showArchiveAlert) { () -> Alert in
            let operationText = viewModel.isTargetDirectoryArchived ? "unarchived" : "archived"
            let countText = viewModel.publishedNoteDocuments.count
            let alertText = """
                Are you sure you want to \(operationText) \(countText) notes?
            """
            return Alert(
                title: Text(alertText),
                primaryButton: cancelButton,
                secondaryButton: archiveActionButton
            )
        }
    }

    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                showArchiveAlert = true
            } label: {
                Image(systemName: viewModel.isTargetDirectoryArchived ? "tray.circle" : "archivebox.circle")
            }
            Button {
                showListConditionSettingView = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            Button {
                viewModel.update()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .disabled(!viewModel.isLoaded)
            Button {
                openNewNote()
            } label: {
                Image(systemName: "plus.circle")
            }
        }
    }

    /// This view is for scrolling to the bottom
    private struct NoteScrollView: View {
        var documents: [NoteDocument]
        var parent: NoteListViewParent

        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    Spacer(minLength: 30.0)
                    NoteListView(documents: documents, parent: parent)
                }
                .padding([.leading, .trailing])
                .navigationBarTitleDisplayMode(.inline)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ScrollButton(
                                action: { scrollToBottom(proxy: proxy) },
                                image: Image(systemName: "arrow.down.circle")
                            )
                        }
                    }
                )
            }
        }

        func scrollToBottom(proxy: ScrollViewProxy) {
            proxy.scrollTo(documents.endIndex - 1, anchor: .bottom)
        }
    }

    private func activityViewController(document: NoteDocument) -> UIActivityViewControllerWrapper {
        let drawing = document.entity.drawing
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        trait.performAsCurrent {
            image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
        }

        return UIActivityViewControllerWrapper(activityItems: [image])
    }

    private func openNewNote() {
        showCanvasView = true
    }

    private var cancelButton: Alert.Button {
        .default(Text("Cancel"))
    }
    private var archiveActionButton: Alert.Button {
        .destructive(
            Text(
                viewModel.isTargetDirectoryArchived
                ? "Unarchived"
                : "Archived"
            ),
            action: {
                viewModel.isTargetDirectoryArchived
                ? viewModel.allUnarchive()
                : viewModel.allArchive()
            }
        )
    }
}

// MARK: - NoteListViewParent

extension NoteListParentView: NoteListViewParent {
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
        documentToShare = document
    }

    func showAddTagView(_ document: NoteDocument) {
        documentToTag = document
    }
}

struct Notes_Previews: PreviewProvider {
    static var previews: some View {
        NoteListParentView(viewModel: NotesViewModel(targetDirectory: .inbox))
            .environmentObject(CanvasViewModel())
    }
}
