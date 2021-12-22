//
//  DrawingsPlistConverter.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/27.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

enum DrawingsPlistConverter {
    static var hasDrawingsPlist: Bool {
        guard let savingUrl = FilePath.savingUrl else { return false }
        let url = savingUrl.appendingPathComponent("drawings.plist")
        return FileManager.default.fileExists(atPath: url.path)
    }

    static func convert() {
        FilePath.makeDirectoryIfNeeded()

        guard let savingUrl = FilePath.savingUrl, let inboxUrl = FilePath.inboxUrl else { return }
        let url = savingUrl.appendingPathComponent("drawings.plist")
        guard FileManager.default.fileExists(atPath: url.path),
                FileManager.default.fileExists(atPath: inboxUrl.path) else { return }

        let document = Document(fileURL: url)
        document.open { success in
            if success {
                document.dataModel.drawings.forEach { drawing in
                    let path = inboxUrl.appendingPathComponent(FilePath.fileName)
                    let newDocument = NoteDocument(fileURL: path, entity: NoteEntity(drawing: drawing))
                    newDocument.save(to: path, for: .forCreating) { _ in
                        // need some error handling
                    }
                }
                let newUrl = savingUrl.appendingPathComponent("converted_drawings.plist")
                try? FileManager.default.moveItem(atPath: url.path, toPath: newUrl.path)
            } else {
                fatalError("could not open document")
            }
        }
    }
}
