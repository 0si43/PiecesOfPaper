//
//  DrawingsPlistConverter.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/27.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

struct DrawingsPlistConverter {
    static func convert() {
        let url = FilePath.iCloudURL.appendingPathComponent("drawings.plist")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        let document = Document(fileURL: url)
        document.open { success in
            if success {
                document.dataModel.drawings.forEach { drawing in
                    let path = FilePath.iCloudURL.appendingPathComponent(FilePath.fileName)
                    let newDocument = NoteDocument(fileURL: path, drawing: drawing)
                    newDocument.save(to: path, for: .forCreating)
                }
                let newUrl = FilePath.iCloudURL.appendingPathComponent("converted_drawings.plist")
                try? FileManager.default.moveItem(atPath: url.path, toPath: newUrl.path)
            } else {
                fatalError("could not open document")
            }
        }
    }
}
