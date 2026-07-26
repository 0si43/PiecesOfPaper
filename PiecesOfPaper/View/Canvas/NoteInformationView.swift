import SwiftUI

struct NoteInformationView: View {
    private(set) var note: NoteData
    @Environment(TagStore.self) private var tagStore
    let dataFormatter: DateFormatter = {
        let dataFormatter = DateFormatter()
        dataFormatter.dateStyle = .medium
        dataFormatter.timeStyle = .medium
        return dataFormatter
    }()

    var body: some View {
        Grid(alignment: .leading, verticalSpacing: 8) {
            #if DEBUG
            GridRow {
                label("🛠ID")
                Text("🛠" + note.entity.id.uuidString)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Divider()
            #endif
            GridRow {
                label("File Name")
                Text(note.fileURL.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Divider()
            GridRow {
                label("Created Date")
                Text(dataFormatter.string(from: note.entity.createdDate))
                    .lineLimit(1)
            }
            Divider()
            GridRow {
                label("Updated Date")
                Text(dataFormatter.string(from: note.entity.updatedDate))
                    .lineLimit(1)
            }
            Divider()
            GridRow {
                label("Archive Status")
                Text(note.isArchived ? "Archived" : "Inbox")
                    .lineLimit(1)
            }
            Divider()
            GridRow {
                label("Tags")
                tagsView
            }
        }
        .padding()
    }

    private func label(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var tagsView: some View {
        let tags = tagStore.tags(ids: note.entity.tagIds)
        if tags.isEmpty {
            Text("No tag")
        } else {
            TagHStack(tags: tags)
                .frame(minHeight: 60)
        }
    }
}

#if DEBUG
#Preview {
    NoteInformationView(note: NoteData.createTestData())
        .environment(TagStore())
}
#endif
