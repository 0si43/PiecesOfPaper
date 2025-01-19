//
//  TagListViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

final class TagListViewModel: ObservableObject {
    private let tagModel = TagModel()
    @Published var tags: [TagEntity] {
        didSet {
            tagModel.save(tags: tags)
        }
    }

    init() {
        tags = tagModel.fetch()
    }

    func remove(indexSet: IndexSet) {
        tags.remove(atOffsets: indexSet)
    }
}
