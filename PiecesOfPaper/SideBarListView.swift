import SwiftUI

struct SideBarListView: View {
    @State private var noteStore = NoteStore()
    @State private var tagStore = TagStore()
    @State private var preferenceStore = PreferenceStore()
    @State private var selection: Page? = .inbox
    @Environment(\.scenePhase) private var scenePhase
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    private enum Page: String, CaseIterable {
        case inbox, trash
        case tag
        case tutorial
        case setting

        var label: String {
            switch self {
            case .inbox: "Inbox"
            case .trash: "Trash"
            case .tag: "Tag List"
            case .tutorial: "Quick Tutorial"
            case .setting: "Setting"
            }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sideBarList
        } detail: {
            switch selection {
            case .inbox:
                NoteListParentView(directory: .inbox)
            case .trash:
                NoteListParentView(directory: .archived)
            case .tag:
                TagList()
            case .tutorial:
                TutorialView()
            case .setting:
                SettingView()
            default:
                Text("Unknown page")
            }
        }
        // Inside the .environment chain: cover content only inherits values
        // injected outside its attachment point
        .fullScreenCover(item: $noteStore.openedNote) { note in
            NavigationStack {
                CanvasView(note: note)
            }
            // CanvasView seeds its @State from init, so an identity change is
            // what swaps the drawing when openedNote is replaced mid-cover
            .id(note.id)
        }
        .onOpenURL { url in
            noteStore.handleIncomingURL(url)
        }
        .alert("", isPresented: $noteStore.showExternalOpenAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(NoteStoreError.openFailed(count: 1).localizedDescription)
        }
        // The store owner, so the flush happens once per app, not once per
        // NoteListParentView
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                noteStore.flushMetadataCache()
            }
        }
        .environment(noteStore)
        .environment(tagStore)
        .environment(preferenceStore)
    }

    private var sideBarList: some View {
        List(selection: $selection) {
            Section(header: Text("Folders")) {
                NavigationLink(value: Page.inbox) {
                    Label(Page.inbox.label, systemImage: "tray")
                }

                NavigationLink(value: Page.trash) {
                    Label(Page.trash.label, systemImage: "trash")
                }
            }
            Section(header: Text("Tag")) {
                NavigationLink(value: Page.tag) {
                    Label(Page.tag.label, systemImage: "tag")
                }
            }
            Section(header: Text("Manage raw data\n(Open Files App)")) {
                Button {
                    if let path = FilePath.inboxUrl?.path(),
                       let url = URL(string: "shareddocuments://" + path),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label(Page.inbox.label, systemImage: "tray")
                }
                Button {
                    if let path = FilePath.archivedUrl?.path(),
                       let url = URL(string: "shareddocuments://" + path),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label(Page.trash.label, systemImage: "trash")
                }
            }
            Section(header: Text("Tutorial")) {
                NavigationLink(value: Page.tutorial) {
                    Label(Page.tutorial.label, systemImage: "text.document")
                }
            }
            Section(header: Text("Setting")) {
                NavigationLink(value: Page.setting) {
                    Label(Page.setting.label, systemImage: "gearshape")
                }
            }
        }
        .navigationTitle("Pieces of Paper")
    }
}
