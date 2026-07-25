import SwiftUI

struct Tag: View {
    private(set) var entity: TagEntity
    private(set) var deletable = false

    var body: some View {
        HStack {
            Text(entity.name)
            if deletable {
                Image(systemName: "multiply.square")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(entity.color.swiftUIColor)
        .cornerRadius(4)
    }
}

#Preview {
    VStack {
        Tag(entity: TagEntity(name: "Memo", color: CodableUIColor(uiColor: UIColor.blue)))
        Tag(entity: TagEntity(name: "Memo", color: CodableUIColor(uiColor: UIColor.gray)), deletable: true)
    }
}
