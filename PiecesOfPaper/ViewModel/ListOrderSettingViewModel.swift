//
//  ListOrderSettingViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/11.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import SwiftUI

@Observable
final class ListOrderSettingViewModel {
    var listOrder: ListOrder
    private var tags: [TagEntity]
    var filteringTag: [TagEntity]
    var nonFilteringTag: [TagEntity]

    // Callback to notify parent of changes
    var onListOrderChanged: ((ListOrder) -> Void)?

    init(listOrder: ListOrder) {
        self.listOrder = listOrder
        let allTags = TagModel().tags
        self.tags = allTags
        self.filteringTag = allTags.filter { listOrder.filterBy.contains($0) }
        self.nonFilteringTag = allTags.filter { !listOrder.filterBy.contains($0) }
    }

    private func updatedFilterTag() {
        filteringTag = tags.filter { listOrder.filterBy.contains($0) }
        nonFilteringTag = tags.filter { !listOrder.filterBy.contains($0) }
    }

    func add(tag: TagEntity) {
        listOrder.filterBy.append(tag)
        updatedFilterTag()
        notifyChange()
    }

    func remove(tag: TagEntity) {
        listOrder.filterBy = listOrder.filterBy.filter { $0 != tag }
        updatedFilterTag()
        notifyChange()
    }

    func updateSortBy(_ newValue: ListOrder.SortBy) {
        listOrder.sortBy = newValue
        notifyChange()
    }

    func updateSortOrder(_ newValue: ListOrder.SortOrder) {
        listOrder.sortOrder = newValue
        notifyChange()
    }

    private func notifyChange() {
        onListOrderChanged?(listOrder)
    }
}
