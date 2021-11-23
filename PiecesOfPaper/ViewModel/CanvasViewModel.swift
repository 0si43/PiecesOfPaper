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
        let data = drawing.dataRepresentation()
        document?.drawingData = data
        if let document = document {
            document.save(to: document.fileURL, for: .forOverwriting)
        } else {
            let path = FilePath.iCloudURL.appendingPathComponent(FilePath.fileName)
            document = NoteDocument(fileURL: path)
            document?.save(to: path, for: .forCreating)
        }
    }
}
