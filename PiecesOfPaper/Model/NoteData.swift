//
//  NoteData.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2026/07/18.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

struct NoteData: Identifiable, Equatable {
    var entity: NoteEntity
    let fileURL: URL

    var id: UUID { entity.id }

    var isArchived: Bool {
        guard let archivedUrl = FilePath.archivedUrl else { return false }
        return fileURL.path.hasPrefix(archivedUrl.path)
    }
}

extension NoteData {
    static func createTestData(fileURL: URL = URL(fileURLWithPath: "/test")) -> NoteData {
        NoteData(entity: NoteEntity(drawing: PKDrawing()), fileURL: fileURL)
    }
}
