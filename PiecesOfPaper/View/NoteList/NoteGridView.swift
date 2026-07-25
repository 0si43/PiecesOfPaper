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
                    let tags = tagStore.tags(ids: noteStore.tagIds(for: entry))
                    VStack {
                        NoteThumbnailView(entry: entry, tags: tags)
                        .contextMenu {
                            contextMenu(entry: entry)
                        }
                        TagHStack(tags: tags)
                            .frame(width: 250, height: 40)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                presentation.requestTag(entry, from: noteStore)
                            }
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
                    Task {
                        do {
                            try await noteStore.unarchive(entry)
                        } catch {
                            presentation.alert = .error(error)
                        }
                    }
                } label: {
                    Label("Move to Inbox", systemImage: "tray")
                }
                Button(role: .destructive) {
                    Task {
                        do {
                            try await noteStore.delete(entry)
                        } catch {
                            presentation.alert = .error(error)
                        }
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button {
                    Task {
                        do {
                            try await noteStore.archive(entry)
                        } catch {
                            presentation.alert = .error(error)
                        }
                    }
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
