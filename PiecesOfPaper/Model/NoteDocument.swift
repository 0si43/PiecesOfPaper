//
//  NoteDocument.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/23.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import PencilKit

final class NoteDocument: UIDocument {
    var drawing: PKDrawing
    
    init(fileURL: URL, drawing: PKDrawing = PKDrawing()) {
        self.drawing = drawing
        super.init(fileURL: fileURL)
    }
    
    override func contents(forType typeName: String) throws -> Any {
        return drawing.dataRepresentation()
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let contents = contents as? Data,
              let drawing = try? PKDrawing(data: contents) else { return }
        self.drawing = drawing
    }
}
