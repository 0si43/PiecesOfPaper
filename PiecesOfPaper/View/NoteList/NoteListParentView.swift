//
//  NoteListParentView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteListParentView: View {
    @Bindable var viewModel: NoteViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showListOrderSettingView = false

    var body: some View {
        Group {
            if viewModel.isShowLoading {
                ProgressView()
            } else {
                if viewModel.displayNoteDocuments.isEmpty {
                    Text("No Data")
                        .font(.largeTitle)
                } else {
                    NoteScrollView(viewModel: viewModel)
                }
            }
        }
        .task {
            if DrawingsPlistConverter.hasDrawingsPlist {
                DrawingsPlistConverter.convert()
            }

            guard !UserPreference().shouldGrantiCloud else {
                viewModel.alertType = .iCloudDenied
                viewModel.showAlert = true
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
        .fullScreenCover(isPresented: $viewModel.showCanvasView) {
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
        .sheet(item: $viewModel.documentToShare) { document in
            activityViewController(document: document)
        }
        .sheet(item: $viewModel.documentToTag,
               onDismiss: {
                   Task {
                       await viewModel.incrementalFetch()
                   }
               }, content: { document in
            AddTagView(viewModel: TagListToNoteViewModel(noteDocument: document))
        })
        .alert("",
               isPresented: $viewModel.showAlert,
               presenting: viewModel.alertType) { type in
                switch type {
                case .iCloudDenied:
                    iCloudButton
                    localStorageButton
                case .archive:
                    archiveActionButton
                case .error:
                    Text("OK")
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
                case let .error(error):
                    return Text(error.localizedDescription)
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
                viewModel.showCanvasView = true
            default:
                break
            }
        }
    }

    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    viewModel.alertType = .archive
                    viewModel.showAlert = true
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
                viewModel.showCanvasView = true
            } label: {
                Image(systemName: "square.and.pencil")
            }
        }
    }

    /// This view is for scrolling to the bottom
    private struct NoteScrollView: View {
        var viewModel: NoteViewModel

        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    Spacer(minLength: 30.0)
                    NoteListView(viewModel: viewModel)
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
            proxy.scrollTo(viewModel.displayNoteDocuments.endIndex - 1, anchor: .bottom)
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
