//
//  ListOrderSettingView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/11.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

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
                    Text(sortBy.rawValue)
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
                    Text(sortOrder.rawValue)
                        .tag(sortOrder)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text("Filter by")
                Spacer()
            }
            .padding(.horizontal)
            TagHStack(tags: filteringTags,
                      action: { removed in listOrder.filterBy.removeAll { $0 == removed } },
                      deletable: true)
                .padding(.horizontal)
            VStack {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add a tag")
                    Spacer()
                }
                .padding(.horizontal)
                TagHStack(tags: nonFilteringTags, action: { listOrder.filterBy.append($0) })
                    .padding(.horizontal)
            }
            .background(Color.gray.opacity(0.2))
            .padding()
            Spacer()

        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                }
            }
        }
        .navigationTitle("Sort & filter condition")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @Previewable @State var listOrder = ListOrder()
    ListOrderSettingView(listOrder: $listOrder)
        .environment(TagStore())
}
