//
//  ListOrderSettingView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/11.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct ListOrderSettingView: View {
    @State private var viewModel: ListOrderSettingViewModel
    @Binding private var parentListOrder: ListOrder
    @Environment(\.dismiss) private var dismiss

    init(listOrder: Binding<ListOrder>) {
        self._parentListOrder = listOrder
        self._viewModel = State(initialValue: ListOrderSettingViewModel(listOrder: listOrder.wrappedValue))
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "arrowtriangle.down.circle")
                Text("Sort By")
                Spacer()
            }
            .padding(.horizontal)
            Picker("", selection: $viewModel.listOrder.sortBy) {
                ForEach(ListOrder.SortBy.allCases) { sortBy in
                    Text(sortBy.rawValue)
                        .tag(sortBy)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: viewModel.listOrder.sortBy) { _, newValue in
                viewModel.updateSortBy(newValue)
            }
            HStack {
                Image(systemName: "arrow.up.arrow.down.circle")
                Text("Sort Order")
                Spacer()
            }
            .padding(.horizontal)
            Picker("", selection: $viewModel.listOrder.sortOrder) {
                ForEach(ListOrder.SortOrder.allCases) { sortOrder in
                    Text(sortOrder.rawValue)
                        .tag(sortOrder)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: viewModel.listOrder.sortOrder) { _, newValue in
                viewModel.updateSortOrder(newValue)
            }
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text("Filter by")
                Spacer()
            }
            .padding(.horizontal)
            TagHStack(tags: viewModel.filteringTag, action: viewModel.remove, deletable: true)
                .padding(.horizontal)
            VStack {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add a tag")
                    Spacer()
                }
                .padding(.horizontal)
                TagHStack(tags: viewModel.nonFilteringTag, action: viewModel.add)
                    .padding(.horizontal)
            }
            .background(Color.gray.opacity(0.2))
            .padding()
            Spacer()

        }
        .onAppear {
            viewModel.onListOrderChanged = { [self] newListOrder in
                self.parentListOrder = newListOrder
            }
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
}
