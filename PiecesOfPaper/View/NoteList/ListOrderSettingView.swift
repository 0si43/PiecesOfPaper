import SwiftUI

struct ListOrderSettingView: View {
    @Binding var listOrder: ListOrder
    @Environment(TagStore.self) private var tagStore
    @Environment(\.dismiss) private var dismiss

    private var filteringTags: [TagEntity] {
        tagStore.filteringTags(from: listOrder.filterBy)
    }

    private var nonFilteringTags: [TagEntity] {
        tagStore.nonFilteringTags(from: listOrder.filterBy)
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "arrowtriangle.down.circle")
                Text("Sort By")
                Spacer()
            }
            .padding(.horizontal)
            Picker("", selection: $listOrder.sortBy) {
                ForEach(ListOrder.SortBy.allCases) { sortBy in
                    Text(sortBy.label)
                        .tag(sortBy)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            HStack {
                Image(systemName: "arrow.up.arrow.down.circle")
                Text("Sort Order")
                Spacer()
            }
            .padding(.horizontal)
            Picker("", selection: $listOrder.sortOrder) {
                ForEach(ListOrder.SortOrder.allCases) { sortOrder in
                    Text(sortOrder.label)
                        .tag(sortOrder)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text("Filter By")
                Spacer()
            }
            .padding(.horizontal)
            TagHStack(tags: filteringTags,
                      action: { removed in listOrder.filterBy.removeAll { $0.id == removed.id } },
                      deletable: true)
                .frame(minHeight: 60)
                .padding(.horizontal)
            VStack {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add a tag")
                    Spacer()
                }
                .padding(.horizontal)
                TagHStack(tags: nonFilteringTags, action: { listOrder.filterBy.append($0) })
                    .frame(minHeight: 60)
                    .padding(.horizontal)
            }
            .background(Color.gray.opacity(0.2))
            .padding()
            Spacer()

        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // The pickers write straight through the binding, so this only
                // dismisses
                SheetCloseButton { dismiss() }
            }
        }
        .navigationTitle("Sort & Filter")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @Previewable @State var listOrder = ListOrder()
    ListOrderSettingView(listOrder: $listOrder)
        .environment(TagStore())
}
