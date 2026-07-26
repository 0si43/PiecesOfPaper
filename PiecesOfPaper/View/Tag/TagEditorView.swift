import SwiftUI

/// The sheet body shared by tag creation and tag editing. It snapshots the tag
/// it is handed into @State, so the draft starts fresh on every presentation
/// and the id the caller passed in survives the edit.
struct TagEditorView: View {
    private(set) var title: String
    private(set) var onSave: (TagEntity) -> Void
    @State private var draft: TagEntity
    @State private var color: Color
    @Environment(\.dismiss) private var dismiss

    init(title: String, tag: TagEntity, onSave: @escaping (TagEntity) -> Void) {
        self.title = title
        self.onSave = onSave
        _draft = State(initialValue: tag)
        _color = State(initialValue: tag.color.opaqueColor)
    }

    private var edited: TagEntity {
        var edited = draft
        edited.color = CodableUIColor(uiColor: UIColor(color))
        return edited
    }

    var body: some View {
        NavigationStack {
            VStack {
                Tag(entity: edited)
                HStack {
                    Text("Tag Name: ")
                    TextField("", text: $draft.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                ColorPicker("Tag Color", selection: $color, supportsOpacity: false)
                .padding()
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: cancel) {
                        Text("Cancel")
                        .foregroundColor(.red)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: save) {
                        Text("Done")
                    }
                }
            }
        }
    }

    private func cancel() {
        dismiss()
    }

    private func save() {
        onSave(edited)
        dismiss()
    }
}

#Preview {
    TagEditorView(title: "Edit Tag",
                  tag: TagEntity(name: "🏷Tag", color: CodableUIColor(uiColor: .systemBlue))) { _ in }
}
