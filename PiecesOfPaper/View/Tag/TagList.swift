import SwiftUI

struct TagList: View {
    @Environment(TagStore.self) private var tagStore

    var body: some View {
        List {
            Section(footer: AddTagFooter(onSave: { tagStore.add($0) })) {
                ForEach(tagStore.tags, id: \.id) { tag in
                    Tag(entity: tag)
                }
                .onDelete { indexSet in
                    tagStore.remove(at: indexSet)
                }
            }
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
