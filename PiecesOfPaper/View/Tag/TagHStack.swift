import SwiftUI

struct TagHStack: View {
    private(set) var tags: [TagEntity]
    private(set) var action: ((TagEntity) -> Void)?
    private(set) var deletable = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.id) { tag in
                    // Attach the tap gesture only when a per-tag action exists:
                    // an always-attached gesture would swallow taps meant for a
                    // caller's whole-strip gesture (NoteGridView)
                    if let action {
                        Tag(entity: tag, deletable: deletable)
                            .onTapGesture { action(tag) }
                    } else {
                        Tag(entity: tag, deletable: deletable)
                    }
                }
            }
        }
    }
}

#Preview {
    let blue = TagEntity(id: UUID(), name: "blue", color: CodableUIColor(uiColor: .blue))
    let yellow = TagEntity(id: UUID(), name: "yellow", color: CodableUIColor(uiColor: .yellow))
    let red = TagEntity(id: UUID(), name: "red", color: CodableUIColor(uiColor: .red))
    return TagHStack(tags: [blue, yellow, red])
        .frame(minHeight: 60)
}
