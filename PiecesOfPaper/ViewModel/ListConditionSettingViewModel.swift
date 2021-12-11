//
//  ListConditionSettingViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/11.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import SwiftUI

class ListConditionSettingViewModel: ObservableObject {
    var bindingListCondition: Binding<ListCondition>
    @Published var editableListCondition: ListCondition
    var tags = TagModel().tags
    var filteringTag: [TagEntity] {
        tags.filter {
            editableListCondition.filterBy.contains($0)
        }
    }

    init(listCondition: Binding<ListCondition>) {
        self.bindingListCondition = listCondition
        self.editableListCondition = listCondition.wrappedValue
    }

    var nonFilteringTag: [TagEntity] {
        tags.filter {
            !editableListCondition.filterBy.contains($0)
        }
    }

    func add(tag: TagEntity) {
        editableListCondition.filterBy.append(tag)
    }

    func remove(tag: TagEntity) {
        editableListCondition.filterBy = editableListCondition.filterBy.filter { $0 != tag }
    }

    func bind() {
        bindingListCondition.wrappedValue = editableListCondition
    }
}
