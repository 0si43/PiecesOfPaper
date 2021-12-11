//
//  ListConditionSettingViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/11.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

class ListConditionSettingViewModel: ObservableObject {
    @Published var listCondition: ListCondition
    var tags = TagModel().tags
    var filteringTag: [TagEntity] {
        tags.filter {
            listCondition.filterBy.contains($0)
        }
    }

    var nonFilteringTag: [TagEntity] {
        tags.filter {
            !listCondition.filterBy.contains($0)
        }
    }

    init(listCondition: ListCondition) {
        self.listCondition = listCondition
    }

    func add(tag: TagEntity) {
        listCondition.filterBy.append(tag)
    }

    func remove(tag: TagEntity) {
        listCondition.filterBy = listCondition.filterBy.filter { $0 != tag }
    }
}
