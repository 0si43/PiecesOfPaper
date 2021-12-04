//
//  CanvasViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

final class CanvasViewModel: ObservableObject {
    var document: NoteDocument?
    
    func save(drawing: PKDrawing) {
        document?.entity.drawing = drawing
        document?.entity.updatedDate = Date()
        if let document = document {
            document.save(to: document.fileURL, for: .forOverwriting)
        } else {
            guard let iCloudInboxUrl = FilePath.iCloudInboxUrl else { return }
            let path = iCloudInboxUrl.appendingPathComponent(FilePath.fileName)
            document = NoteDocument(fileURL: path, entity: NoteEntity(drawing: drawing))
            document?.save(to: path, for: .forCreating)
        }
    }
}
