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
        // Tag colors are RGBA frozen under a light trait and fill at 70%, so on a
        // dark background they darken and lose contrast against the label. The
        // chip keeps a light base in both appearances rather than adapting.
        .foregroundStyle(.black)
        .background(entity.color.swiftUIColor)
        .background(.white)
        .cornerRadius(4)
    }
}

#Preview {
    VStack {
        Tag(entity: TagEntity(name: "Memo", color: CodableUIColor(uiColor: UIColor.blue)))
        Tag(entity: TagEntity(name: "Memo", color: CodableUIColor(uiColor: UIColor.gray)), deletable: true)
    }
}
