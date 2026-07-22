import SwiftUI

struct AddTagView: View {
    // Snapshot from sheet(item:); the latest tags come from the store's
    // metadata cache, which tag edits update optimistically
    let note: NoteData
    @Environment(NoteStore.self) private var noteStore
    @Environment(TagStore.self) private var tagStore
    // This sheet owns its alert: one raised by the presenting screen would be
    // covered by the sheet and never appear
    @State private var saveError: Error?

    private var currentTagIds: [UUID] {
        noteStore.currentTagIds(for: note)
    }

    private var tagsToNote: [TagEntity] {
        tagStore.tags(ids: currentTagIds)
    }

    private var tagsNotToNote: [TagEntity] {
        tagStore.tagsNotIn(ids: currentTagIds)
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
        .alert("",
               isPresented: Binding(get: { saveError != nil },
                                    set: { if !$0 { saveError = nil } }),
               presenting: saveError) { _ in
            Text("OK")
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private func add(_ tag: TagEntity) {
        update { try await noteStore.addTag(tag, to: note) }
    }

    private func remove(_ tag: TagEntity) {
        update { try await noteStore.removeTag(tag, from: note) }
    }

    private func update(_ operation: @escaping () async throws -> Void) {
        Task {
            do {
                try await operation()
            } catch {
                saveError = error
            }
        }
    }
}

#Preview {
    AddTagView(note: NoteData.createTestData())
        .environment(NoteStore())
        .environment(TagStore())
}
