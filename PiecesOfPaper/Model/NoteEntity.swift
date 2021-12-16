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
    var id = UUID()
    var drawing: PKDrawing
    var tags: [TagEntity]
    var createdDate: Date
    var updatedDate: Date

    init(drawing: PKDrawing,
         tags: [TagEntity] = [],
         createdDate: Date = Date(),
         updatedDate: Date = Date()) {
        self.drawing = drawing
        self.tags = tags
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }
}
