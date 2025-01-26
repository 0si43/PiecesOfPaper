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
    @Environment(\.scenePhase) private var scenePhase
    @State private var showCanvasView = false
    @State private var showListOrderSettingView = false
    @State private var documentToShare: NoteDocument?
    @State private var documentToTag: NoteDocument?
    @State private var showAlert = false
    @State private var alertType: AlertType?

    private enum AlertType {
        case iCloudDenied, archive
    }

    var body: some View {
        Group {
            if viewModel.isShowLoading {
                ProgressView()
            } else {
                if viewModel.displayNoteDocuments.isEmpty {
                    Text("No Data")
                        .font(.largeTitle)
                } else {
                    NoteScrollView(documents: $viewModel.displayNoteDocuments, parent: self)
                }
            }
        }
        .task {
            if DrawingsPlistConverter.hasDrawingsPlist {
                DrawingsPlistConverter.convert()
            }

            guard !UserPreference().shouldGrantiCloud else {
                alertType = .iCloudDenied
                showAlert = true
                return
            }

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
            if let path = FilePath.inboxUrl?.appendingPathComponent(FilePath.fileName) {
                NavigationStack {
                    CanvasView(canvasViewModel: CanvasViewModel(path: path))
                }
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
        .sheet(item: $documentToTag,
               onDismiss: {
                   Task {
                       await viewModel.incrementalFetch()
                   }
               }, content: { document in
            AddTagView(viewModel: TagListToNoteViewModel(noteDocument: document))
        })
        .alert("",
               isPresented: $showAlert,
               presenting: alertType) { type in
                switch type {
                case .iCloudDenied:
                    iCloudButton
                    localStorageButton
                case .archive:
                    archiveActionButton
                }
            } message: { type in
                switch type {
                case .iCloudDenied:
                    return Text("The app could not access your iCloud Drive. You should change setting")
                case .archive:
                    let operationText = viewModel.isTargetDirectoryArchived ? "unarchived" : "archived"
                    let countText = viewModel.displayNoteDocuments.count
                    let alertText = """
                        Are you sure you want to \(operationText) \(countText) notes?
                    """
                    return Text(alertText)
                }
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
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                guard !UserPreference().shouldGrantiCloud else { return }
                showCanvasView = true
            default:
                break
            }
        }
    }

    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    alertType = .archive
                    showAlert = true
                } label: {
                    Label(viewModel.isTargetDirectoryArchived
                          ? "Move all to Inbox"
                          : "Move all to Trash",
                          systemImage: viewModel.isTargetDirectoryArchived
                          ? "tray.circle"
                          : "trash"
                    )
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
                showCanvasView = true
            } label: {
                Image(systemName: "square.and.pencil")
            }
        }
    }

    /// This view is for scrolling to the bottom
    private struct NoteScrollView: View {
        @Binding var documents: [NoteDocument]
        var parent: NoteListViewParent

        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    Spacer(minLength: 30.0)
                    NoteListView(documents: $documents, parent: parent)
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

    // MARK: - Alert Components

    private var iCloudButton: some View {
        Button {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        } label: {
            Text("Use iCloud")
        }
    }

    private var localStorageButton: some View {
        Button {
            var userPreference = UserPreference()
            userPreference.enablediCloud = false
            Task {
                await viewModel.incrementalFetch()
            }
        } label: {
            Text("Use device storage")
        }
    }

    private var archiveActionButton: some View {
        Button(role: .destructive) {
            viewModel.isTargetDirectoryArchived
            ? viewModel.allUnarchive()
            : viewModel.allArchive()
        } label: {
            Text(
                viewModel.isTargetDirectoryArchived
                ? "Move all to Inbox"
                : "Move all to Trash"
            )
        }
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
