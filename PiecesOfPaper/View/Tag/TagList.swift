import SwiftUI

struct TagList: View {
    @Environment(TagStore.self) private var tagStore
    @State private var editingTag: TagEntity?

    var body: some View {
        List {
            Section(footer: AddTagFooter(onSave: { tagStore.add($0) })) {
                ForEach(tagStore.tags, id: \.id) { tag in
                    HStack {
                        Tag(entity: tag)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingTag = tag
                    }
                    .accessibilityAddTraits(.isButton)
                }
                .onDelete { indexSet in
                    tagStore.remove(at: indexSet)
                }
            }
        }
        // On the List, not the row: rows are lazy, and one scrolled out of view
        // would take its sheet with it
        .sheet(item: $editingTag) { tag in
            TagEditorView(title: "Edit Tag", tag: tag) { tagStore.update($0) }
        }
        .onAppear {
            tagStore.reload()
        }
    }
}

#Preview {
    TagList()
        .environment(TagStore())
}
