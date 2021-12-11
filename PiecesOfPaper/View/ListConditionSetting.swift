//
//  ListConditionSetting.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/11.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct ListConditionSetting: View {
    @ObservedObject var viewModel = ListConditionSettingViewModel()

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "arrowtriangle.down.circle")
                Text("Sort By")
                Spacer()
            }
            .padding(.horizontal)
            Picker("", selection: $viewModel.listCondition.sortBy) {
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
            Picker("", selection: $viewModel.listCondition.sortOrder) {
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
            TagHStack(tags: viewModel.filteringTag)
                .padding(.horizontal)
            HStack {
                Image(systemName: "plus.circle")
                Text("Add a tag")
                Spacer()
            }
            .padding(.horizontal)
            TagHStack(tags: viewModel.nonFilteringTag, action: viewModel.add)
                .padding(.horizontal)
            Spacer()

        }
        .navigationBarItems(leading:
            Button(action: {}) {
                Text("Cancel")
                .foregroundColor(.red)
            }
        )
        .navigationBarItems(trailing:
            Button(action: apply) {
                Text("Apply")
            }
        )
        .navigationTitle("Sort & filter condition")
        .navigationBarTitleDisplayMode(.inline)
    }

    func cancel() {

    }

    func apply() {

    }
}

struct ListConditionSetting_Previews: PreviewProvider {
    static var previews: some View {
        ListConditionSetting()
    }
}
