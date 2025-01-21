//
//  NoteListParentView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteListParentView: View {
    @ObservedObject private(set) var viewModel: NoteViewModel
    @State private var showCanvasView = false
    @State private var showListOrderSettingView = false
    @State private var documentToShare: NoteDocument?
    @State private var documentToTag: NoteDocument?
    @State private var showArchiveAlert = false

    var body: some View {
        Group {
            if viewModel.isShowLoading {
                ProgressView()
            } else {
                if viewModel.displayNoteDocuments.isEmpty {
                    Text("No Data")
                        .font(.largeTitle)
                } else {
                    NoteScrollView(documents: viewModel.displayNoteDocuments, parent: self)
                }
            }
        }
        .task {
            await viewModel.incrementalFetch()
        }
        .refreshable {
            Task {
                await viewModel.reload()
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
        .sheet(isPresented: $showListOrderSettingView) {
            NavigationView {
                ListOrderSettingView(listOrder: $viewModel.listOrder)
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
            let countText = viewModel.displayNoteDocuments.count
            let alertText = """
                Are you sure you want to \(operationText) \(countText) notes?
            """
            return Alert(
                title: Text(alertText),
                primaryButton: cancelButton,
                secondaryButton: archiveActionButton
            )
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .dismissCanvasView
            )
        ) { _ in
            Task {
                await viewModel.incrementalFetch()
            }
        }
    }

    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    showArchiveAlert = true
                } label: {
                    Label(viewModel.isTargetDirectoryArchived ? "Unarchive" : "Archive", systemImage: "tray.circle")
                }
                Button {
                    showListOrderSettingView = true
                } label: {
                    Label("Reorder", systemImage: "line.3.horizontal.decrease.circle")
                }
                Button {
                    Task {
                        await viewModel.reload()
                    }
                } label: {
                    Label("Reload", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(viewModel.isShowLoading)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
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
        NoteListParentView(viewModel: NoteViewModel(targetDirectory: .inbox))
    }
}
