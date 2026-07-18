//
//  NoteListParentView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteListParentView: View {
    let directory: NoteDirectory
    @Environment(NoteStore.self) private var noteStore
    @Environment(TagStore.self) private var tagStore
    @Environment(PreferenceStore.self) private var preferenceStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.displayScale) private var displayScale
    @State private var showListOrderSettingView = false

    private var isTargetDirectoryArchived: Bool {
        directory == .archived
    }

    var body: some View {
        @Bindable var noteStore = noteStore
        Group {
            if noteStore.isLoading {
                ProgressView()
            } else {
                if noteStore.displayDocuments(for: directory).isEmpty {
                    Text("No Data")
                        .font(.largeTitle)
                } else {
                    NoteScrollView(directory: directory)
                }
            }
        }
        .task {
            guard !preferenceStore.shouldGrantiCloud else {
                noteStore.alertType = .iCloudDenied
                noteStore.showAlert = true
                return
            }

            await noteStore.incrementalFetch(directory: directory)
        }
        .refreshable {
            Task {
                await noteStore.reload(directory: directory)
            }
        }
        .toolbar {
            toolbarItems
        }
        .fullScreenCover(isPresented: $noteStore.showCanvasView) {
            if let path = FilePath.inboxUrl?.appendingPathComponent(FilePath.fileName) {
                NavigationStack {
                    CanvasView(canvasViewModel: makeNewNoteCanvasViewModel(path: path))
                }
            }
        }
        .sheet(isPresented: $showListOrderSettingView) {
            NavigationView {
                ListOrderSettingView(
                    listOrder: Binding(
                        get: { noteStore.listOrder(for: directory) },
                        set: { noteStore.setListOrder($0, for: directory) }
                    ),
                    tags: tagStore.tags
                )
            }
        }
        .sheet(item: $noteStore.documentToShare) { document in
            activityViewController(document: document)
        }
        .sheet(item: $noteStore.documentToTag,
               onDismiss: {
                   Task {
                       await noteStore.incrementalFetch(directory: directory)
                   }
               }, content: { document in
            AddTagView(document: document)
        })
        .alert("",
               isPresented: $noteStore.showAlert,
               presenting: noteStore.alertType) { type in
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
                    let operationText = isTargetDirectoryArchived ? "unarchived" : "archived"
                    let countText = noteStore.displayDocuments(for: directory).count
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
                await noteStore.incrementalFetch(directory: directory)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                guard !preferenceStore.shouldGrantiCloud else { return }
                noteStore.showCanvasView = true
            default:
                break
            }
        }
    }

    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    noteStore.alertType = .archive
                    noteStore.showAlert = true
                } label: {
                    Label(isTargetDirectoryArchived
                          ? "Move all to Inbox"
                          : "Move all to Trash",
                          systemImage: isTargetDirectoryArchived
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
                        await noteStore.reload(directory: directory)
                    }
                } label: {
                    Label("Reload", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(noteStore.isLoading)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("More Actions")
            Button {
                noteStore.showCanvasView = true
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .accessibilityLabel("New Note")
        }
    }

    /// This view is for scrolling to the bottom
    private struct NoteScrollView: View {
        let directory: NoteDirectory
        @Environment(NoteStore.self) private var noteStore

        var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    Spacer(minLength: 30.0)
                    NoteListView(directory: directory)
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
                            .accessibilityLabel("Scroll to Bottom")
                        }
                    }
                )
            }
        }

        func scrollToBottom(proxy: ScrollViewProxy) {
            guard let lastDocument = noteStore.displayDocuments(for: directory).last else { return }
            withAnimation {
                proxy.scrollTo(lastDocument.id, anchor: .bottom)
            }
        }
    }

    private func makeNewNoteCanvasViewModel(path: URL) -> CanvasViewModel {
        let canvasViewModel = CanvasViewModel(newNoteAt: path)
        canvasViewModel.onPersisted = { noteStore.upsert($0) }
        return canvasViewModel
    }

    private func activityViewController(document: NoteDocument) -> UIActivityViewControllerWrapper {
        let drawing = document.entity.drawing
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        trait.performAsCurrent {
            image = drawing.image(from: drawing.bounds, scale: displayScale)
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
            preferenceStore.enablediCloud = false
            Task {
                await noteStore.incrementalFetch(directory: directory)
            }
        } label: {
            Text("Use device storage")
        }
    }

    private var archiveActionButton: some View {
        Button(role: .destructive) {
            isTargetDirectoryArchived
            ? noteStore.allUnarchive()
            : noteStore.allArchive()
        } label: {
            Text(
                isTargetDirectoryArchived
                ? "Move all to Inbox"
                : "Move all to Trash"
            )
        }
    }
}
