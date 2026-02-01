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
    @ObservationIgnored @Binding var listOrder: ListOrder
    private var tags = TagModel().tags

    init(listOrder: Binding<ListOrder>) {
        self._listOrder = listOrder
        filteringTag = tags.filter { listOrder.wrappedValue.filterBy.contains($0) }
        nonFilteringTag = tags.filter { !listOrder.wrappedValue.filterBy.contains($0) }
    }

    var filteringTag: [TagEntity]
    var nonFilteringTag: [TagEntity]
    private func updatedFilterTag() {
        filteringTag = tags.filter { listOrder.filterBy.contains($0) }
        nonFilteringTag = tags.filter { !listOrder.filterBy.contains($0) }
    }

    func add(tag: TagEntity) {
        listOrder.filterBy.append(tag)
        updatedFilterTag()
    }

    func remove(tag: TagEntity) {
        listOrder.filterBy = listOrder.filterBy.filter { $0 != tag }
        updatedFilterTag()
    }
}
