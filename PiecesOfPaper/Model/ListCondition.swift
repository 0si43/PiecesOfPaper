//
//  ListCondition.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/11.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

struct ListCondition {
    enum SortBy: String, CaseIterable, Identifiable {
        case createdDate = "created date"
        case updatedDate = "updated date"

        var id: String { self.rawValue }
    }
    var sortBy: SortBy = .updatedDate

    enum SortOrder: String, CaseIterable, Identifiable {
        case ascending, descending

        var id: String { self.rawValue }
    }
    var sortOrder: SortOrder = .descending

    var filterBy = [TagEntity]()
}
