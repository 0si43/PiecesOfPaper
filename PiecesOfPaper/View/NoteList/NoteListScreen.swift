import SwiftUI
import PencilKit

struct NoteListScreen: View {
    let directory: NoteDirectory
    @Environment(NoteStore.self) private var noteStore
    @Environment(PreferenceStore.self) private var preferenceStore
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
            switch preferenceStore.cloudAvailability {
            // Deliberately no fetch: the user decides between iCloud and local
            // first. isLoading must still be cleared or the ProgressView behind
            // the alert spins forever.
            case .signedOut:
                presentation.alert = .iCloudDenied
                noteStore.isLoading = false
            case .driveUnavailable:
                presentation.alert = .iCloudDriveDisabled
                noteStore.isLoading = false
            case .available, .userDisabled:
                await noteStore.fetch(directory: directory)
            }
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
        .sheet(item: $presentation.noteToTag) { note in
            AddTagView(note: note)
        }
        .alert("",
               isPresented: $presentation.isAlertPresented,
               presenting: presentation.alert) { alert in
                switch alert {
                case .iCloudDenied, .iCloudDriveDisabled:
                    iCloudButton
                    localStorageButton
                case .archiveAll:
                    archiveActionButton
                case .localFallback, .error:
                    Text("OK")
                }
            } message: { alert in
                switch alert {
                case .iCloudDenied:
                    return Text("""
                        iCloud is enabled for this app, but this device is not signed in to iCloud. \
                        Sign in from Settings, or use device storage.
                        """)
                case .iCloudDriveDisabled:
                    return Text("""
                        iCloud Drive appears to be disabled for this app. \
                        Allow this app in Settings > Apple Account > iCloud > iCloud Drive, \
                        or use device storage.
                        """)
                case .archiveAll:
                    let operation = isTargetDirectoryArchived ? "unarchive" : "archive"
                    let count = noteStore.displayEntries(for: directory).count
                    return Text("Are you sure you want to \(operation) \(count) \(count == 1 ? "note" : "notes")?")
                case .localFallback:
                    return Text("""
                        iCloud is no longer available, so your notes are now shown from device storage. \
                        Notes saved in iCloud will reappear when iCloud is available again.
                        """)
                case let .error(error):
                    return Text(error.localizedDescription)
                }
        }
        .onChange(of: noteStore.didFallBackToLocalStorage) { _, didFallBack in
            guard didFallBack else { return }
            presentation.alert = .localFallback
            noteStore.acknowledgeLocalStorageFallback()
        }
        // Outermost so the grid, its cells, and the sheets above all see it
        .environment(presentation)
        // Outside the Group, whose branches would each get their own anchor: a torn-down anchor
        // takes the popover with it. Unlike the sheets above it presents a UIKit controller, not
        // SwiftUI content, so it does not need to sit inside the .environment chain
        .shareSheet(item: $presentation.noteToShare,
                    activityItems: { note in
                        [NoteShareItemSource(image: note.entity.drawing.lightModeImage(scale: displayScale),
                                             updatedDate: note.entity.updatedDate)]
                    },
                    // The context menu that started the share has closed by the time the note
                    // finishes loading, so there is nothing left for an arrow to point at
                    permittedArrowDirections: [])
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
            if preferenceStore.cloudAvailability.isDegraded {
                degradedCloudIndicator
            }
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

    // Re-presents the availability alert so the user can act after having
    // dismissed it once
    private var degradedCloudIndicator: some View {
        Button {
            presentation.alert = preferenceStore.cloudAvailability == .signedOut
                ? .iCloudDenied
                : .iCloudDriveDisabled
        } label: {
            Image(systemName: "icloud.slash")
        }
        .accessibilityLabel("iCloud unavailable. Notes are stored on this device.")
    }

    // MARK: - Alert Components

    private var iCloudButton: some View {
        Button {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        } label: {
            Text("Open Settings")
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
            Task {
                do {
                    if isTargetDirectoryArchived {
                        try await noteStore.allUnarchive()
                    } else {
                        try await noteStore.allArchive()
                    }
                } catch {
                    presentation.alert = .error(error)
                }
            }
        } label: {
            Text(
                isTargetDirectoryArchived
                ? "Move all to Inbox"
                : "Move all to Trash"
            )
        }
    }
}
