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
    var entity: NoteEntity

    override init(fileURL: URL) {
        self.entity = NoteEntity(drawing: PKDrawing())
        super.init(fileURL: fileURL)
    }

    init(fileURL: URL, entity: NoteEntity) {
        self.entity = entity
        super.init(fileURL: fileURL)
    }

    override func contents(forType typeName: String) throws -> Any {
        let encoder = PropertyListEncoder()
        let data = (try? encoder.encode(entity)) ?? Data()
        return data
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let content = contents as? Data else { return }
        let decoder = PropertyListDecoder()
        do {
            entity = try decoder.decode(NoteEntity.self, from: content)
        } catch {
            print("Data file format error: ", error.localizedDescription)
        }
    }
}
