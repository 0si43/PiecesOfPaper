import SwiftUI

struct AddTagFooter: View {
    private(set) var onSave: (TagEntity) -> Void
    @State private var isTapped = false

    var body: some View {
        HStack {
            Spacer()
            Image(systemName: "plus.circle")
                .resizable()
                .frame(width: 24.0, height: 24.0)
                .foregroundColor(.blue)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isTapped.toggle()
        }
        .accessibilityLabel("Add Tag")
        .accessibilityAddTraits(.isButton)
        // A fresh entity per presentation, snapshotted by the editor: keeping the
        // draft here let a cancelled or already saved tag reappear the next time
        .sheet(isPresented: $isTapped) {
            TagEditorView(title: "New Tag",
                          tag: TagEntity(name: "🏷Tag", color: CodableUIColor(uiColor: .systemBlue)),
                          onSave: onSave)
        }
    }
}

#Preview {
    AddTagFooter(onSave: { _ in })
}
