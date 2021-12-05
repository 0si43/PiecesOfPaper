//
//  TagListViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

final class TagListViewModel: ObservableObject {
    var model = TagModel()

    init() {
        model.fetch()
    }
}
