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
    @Binding var listOrder: ListOrder
    var tags = TagModel().tags

    init(listOrder: Binding<ListOrder>) {
        self._listOrder = listOrder
    }

    var filteringTag: [TagEntity] {
        tags.filter {
            listOrder.filterBy.contains($0)
        }
    }

    var nonFilteringTag: [TagEntity] {
        tags.filter {
            !listOrder.filterBy.contains($0)
        }
    }

    func add(tag: TagEntity) {
        listOrder.filterBy.append(tag)
    }

    func remove(tag: TagEntity) {
        listOrder.filterBy = listOrder.filterBy.filter { $0 != tag }
    }
}
