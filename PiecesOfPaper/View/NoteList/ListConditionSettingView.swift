//
//  ListConditionSettingView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/11.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct ListConditionSettingView: View {
    @ObservedObject var viewModel: ListConditionSettingViewModel
    @Environment(\.dismiss) private var dismiss

    init(listCondition: Binding<ListCondition>) {
        self.viewModel = ListConditionSettingViewModel(listCondition: listCondition)
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "arrowtriangle.down.circle")
                Text("Sort By")
                Spacer()
            }
            .padding(.horizontal)
            Picker("", selection: $viewModel.editableListCondition.sortBy) {
                ForEach(ListCondition.SortBy.allCases) { sortBy in
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
            Picker("", selection: $viewModel.editableListCondition.sortOrder) {
                ForEach(ListCondition.SortOrder.allCases) { sortOrder in
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
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: cancel) {
                    Text("Cancel")
                    .foregroundColor(.red)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: apply) {
                    Text("Apply")
                }
            }
        }
        .navigationTitle("Sort & filter condition")
        .navigationBarTitleDisplayMode(.inline)
    }

    func cancel() {
        dismiss()
    }

    func apply() {
        viewModel.bind()
        dismiss()
    }
}

struct ListConditionSetting_Previews: PreviewProvider {
    @State static var listCondition = ListCondition()
    static var previews: some View {
        ListConditionSettingView(listCondition: $listCondition)
    }
}
