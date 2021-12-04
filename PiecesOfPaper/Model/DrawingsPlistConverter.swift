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
        makeDirectoryIfNeeded()
        
        guard let iCloudUrl = FilePath.iCloudUrl, let inboxUrl = FilePath.iCloudInboxUrl else { return }
        let url = iCloudUrl.appendingPathComponent("drawings.plist")
        guard FileManager.default.fileExists(atPath: url.path), FileManager.default.fileExists(atPath: inboxUrl.path) else { return }
        
        let document = Document(fileURL: url)
        document.open { success in
            if success {
                document.dataModel.drawings.forEach { drawing in
                    let path = inboxUrl.appendingPathComponent(FilePath.fileName)
                    let newDocument = NoteDocument(fileURL: path, drawing: drawing)
                    newDocument.save(to: path, for: .forCreating) { result in
                        print(result)
                    }
                }
                let newUrl = iCloudUrl.appendingPathComponent("converted_drawings.plist")
                try? FileManager.default.moveItem(atPath: url.path, toPath: newUrl.path)
            } else {
                fatalError("could not open document")
            }
        }
    }
    
    private static func makeDirectoryIfNeeded() {
        guard let inboxUrl = FilePath.iCloudInboxUrl, let iCloudArchivedUrl = FilePath.iCloudArchivedUrl else { return }
        if !FileManager.default.fileExists(atPath: inboxUrl.path) {
            try? FileManager.default.createDirectory(at: inboxUrl, withIntermediateDirectories: false)
        }
        
        if !FileManager.default.fileExists(atPath: iCloudArchivedUrl.path) {
            try? FileManager.default.createDirectory(at: iCloudArchivedUrl, withIntermediateDirectories: false)
        }
    }
}
