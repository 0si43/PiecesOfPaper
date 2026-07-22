import SwiftUI
import PencilKit

struct NoteListScreen: View {
    let directory: NoteDirectory
    @Environment(NoteStore.self) private var noteStore
    @Environment(PreferenceStore.self) private var preferenceStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.displayScale) private var displayScale
    @State private var showListOrderSettingView = false
    @State private var presentation = NoteListPresentation()

    private var isTargetDirectoryArchived: Bool {
        directory == .archived
    }

    var body: some View {
        @Bindable var presentation = presentation
        Group {
            if noteStore.isLoading {
                ProgressView()
            } else {
                if noteStore.displayEntries(for: directory).isEmpty {
                    // While a tag filter hydrates, nothing may match yet;
                    // the empty state would be premature
                    if noteStore.isFilterHydrating(for: directory) {
                        ProgressView()
                    } else {
                        emptyStateView
                    }
                } else {
                    NoteGridView(directory: directory)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !preferenceStore.shouldGrantiCloud else {
                presentation.alert = .iCloudDenied
                return
            }

            await noteStore.fetch(directory: directory)
        }
        .refreshable {
            await noteStore.fetch(directory: directory, background: true)
        }
        .toolbar {
            toolbarItems
        }
        .sheet(isPresented: $showListOrderSettingView) {
            NavigationStack {
                ListOrderSettingView(
                    listOrder: Binding(
                        get: { noteStore.listOrder(for: directory) },
                        set: { noteStore.setListOrder($0, for: directory) }
                    )
                )
            }
        }
        .sheet(item: $presentation.noteToShare) { note in
            activityViewController(note: note)
        }
        .sheet(item: $presentation.noteToTag) { note in
            AddTagView(note: note)
        }
        .alert("",
               isPresented: $presentation.isAlertPresented,
               presenting: presentation.alert) { alert in
                switch alert {
                case .iCloudDenied:
                    iCloudButton
                    localStorageButton
                case .archiveAll:
                    archiveActionButton
                case .error:
                    Text("OK")
                }
            } message: { alert in
                switch alert {
                case .iCloudDenied:
                    return Text("The app could not access your iCloud Drive. You should change setting")
                case .archiveAll:
                    let operationText = isTargetDirectoryArchived ? "unarchived" : "archived"
                    let countText = noteStore.displayEntries(for: directory).count
                    let alertText = """
                        Are you sure you want to \(operationText) \(countText) notes?
                    """
                    return Text(alertText)
                case let .error(error):
                    return Text(error.localizedDescription)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                guard !preferenceStore.shouldGrantiCloud else { return }
                noteStore.openBlankNoteIfIdle()
            default:
                break
            }
        }
        // Outermost so the grid, its cells, and the sheets above all see it
        .environment(presentation)
    }

    // Not a bare ContentUnavailableView: `.refreshable` only exposes the
    // pull-to-refresh gesture inside a scrollable container
    private var emptyStateView: some View {
        ScrollView {
            ContentUnavailableView(
                "No Notes",
                systemImage: "note.text",
                description: Text("Pull down to refresh.")
            )
            .containerRelativeFrame(.vertical)
        }
    }

    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    presentation.alert = .archiveAll
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
                        await noteStore.fetch(directory: directory)
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
                noteStore.openNewNote()
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .accessibilityLabel("New Note")
        }
    }

    private func activityViewController(note: NoteData) -> UIActivityViewControllerWrapper {
        let drawing = note.entity.drawing
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
                await noteStore.fetch(directory: directory)
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
