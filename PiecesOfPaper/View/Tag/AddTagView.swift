import SwiftUI

struct AddTagView: View {
    // Snapshot from sheet(item:); the latest tags come from the store's
    // metadata cache, which tag edits update optimistically
    let note: NoteData
    @Environment(NoteStore.self) private var noteStore
    @Environment(TagStore.self) private var tagStore

    private var currentTags: [TagEntity] {
        noteStore.currentTags(for: note)
    }

    private var tagsToNote: [TagEntity] {
        tagStore.tagsMatching(currentTags)
    }

    private var tagsNotToNote: [TagEntity] {
        tagStore.tagsNotMatching(currentTags)
    }

    var body: some View {
        List {
            TagHStack(tags: tagsToNote, action: remove, deletable: true)
            Section(header: Text("Select tag which you want to add")) {
                ForEach(tagsNotToNote, id: \.id) { tag in
                    HStack {
                        Tag(entity: tag)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        add(tag)
                    }
                }
            }
        }
        .onAppear {
            tagStore.reload()
        }
    }

    private func add(_ tag: TagEntity) {
        noteStore.addTag(tag, to: note)
    }

    private func remove(_ tag: TagEntity) {
        noteStore.removeTag(tag, from: note)
    }
}

#Preview {
    AddTagView(note: NoteData.createTestData())
        .environment(NoteStore())
        .environment(TagStore())
}
