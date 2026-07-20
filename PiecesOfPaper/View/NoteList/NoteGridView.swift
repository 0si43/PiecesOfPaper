import SwiftUI

struct NoteGridView: View {
    let directory: NoteDirectory
    @Environment(NoteStore.self) private var noteStore
    @Environment(TagStore.self) private var tagStore
    @Environment(NoteListPresentation.self) private var presentation
    private let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)

    var body: some View {
        ScrollView {
            Spacer(minLength: 30.0)
            LazyVGrid(columns: [gridItem]) {
                ForEach(noteStore.displayEntries(for: directory)) { entry in
                    VStack {
                        NoteThumbnailView(entry: entry)
                        .contextMenu {
                            contextMenu(entry: entry)
                        }
                        NoteListTagHStack(
                            tags: tagStore.tagsMatching(noteStore.tags(for: entry)),
                            action: {
                                presentation.requestTag(entry, from: noteStore)
                            }
                        )
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding([.leading, .trailing])
    }

    func contextMenu(entry: NoteIndexEntry) -> some View {
        Group {
            Button {
                Task {
                    do {
                        try await noteStore.duplicate(entry, in: directory)
                    } catch {
                        presentation.alert = .error(error)
                    }
                }
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            if entry.isArchived {
                Button {
                    noteStore.unarchive(entry)
                } label: {
                    Label("Move to Inbox", systemImage: "tray")
                }
                Button(role: .destructive) {
                    do {
                        try noteStore.delete(entry)
                    } catch {
                        presentation.alert = .error(error)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button {
                    noteStore.archive(entry)
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
            }
            Button {
                presentation.requestShare(entry, from: noteStore)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                presentation.requestTag(entry, from: noteStore)
            } label: {
                Label("Tag", systemImage: "tag")
            }
        }
    }
}
