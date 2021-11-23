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
        document?.drawing = drawing
        if let document = document {
            document.save(to: document.fileURL, for: .forOverwriting)
        } else {
            let path = FilePath.iCloudURL.appendingPathComponent(FilePath.fileName)
            document = NoteDocument(fileURL: path, drawing: drawing)
            document?.save(to: path, for: .forCreating)
        }
    }
}
