//
//  NoteDocument.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/23.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit

final class NoteDocument: UIDocument {
    var drawingData: Data?
    
    enum NoteDocumentError: Error {
        case noContent
    }
    
    override func contents(forType typeName: String) throws -> Any {
        guard let drawingData = drawingData else { throw NoteDocumentError.noContent }
        return drawingData
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let contents = contents as? Data else { return }
        self.drawingData = contents
    }
}
