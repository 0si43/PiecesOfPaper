//
//  ListOrderSettingViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/11.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import SwiftUI

class ListOrderSettingViewModel: ObservableObject {
    var bindingListOrder: Binding<ListOrder>
    @Published var editableListOrder: ListOrder
    var tags = TagModel().tags
    var filteringTag: [TagEntity] {
        tags.filter {
            editableListOrder.filterBy.contains($0)
        }
    }

    init(listOrder: Binding<ListOrder>) {
        self.bindingListOrder = listOrder
        self.editableListOrder = listOrder.wrappedValue
    }

    var nonFilteringTag: [TagEntity] {
        tags.filter {
            !editableListOrder.filterBy.contains($0)
        }
    }

    func add(tag: TagEntity) {
        editableListOrder.filterBy.append(tag)
    }

    func remove(tag: TagEntity) {
        editableListOrder.filterBy = editableListOrder.filterBy.filter { $0 != tag }
    }

    func bind() {
        bindingListOrder.wrappedValue = editableListOrder
    }
}
