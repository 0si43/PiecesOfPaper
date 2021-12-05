//
//  NoteEntity.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/04.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

struct NoteEntity: Codable {
    var drawing: PKDrawing
    var tags: [String]
    var createdDate: Date
    var updatedDate: Date
    var isArchived: Bool

    init(drawing: PKDrawing,
         tags: [String] = [],
         createdDate: Date = Date(),
         updatedDate: Date = Date(),
         isArchived: Bool = false) {
        self.drawing = drawing
        self.tags = tags
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.isArchived = isArchived
    }
}
