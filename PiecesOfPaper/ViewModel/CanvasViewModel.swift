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
    
    var iCloudURL: URL {
        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)!
            .appendingPathComponent("Documents")
        return url
    }
    
    var fileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ssSSSS"
        return dateFormatter.string(from: Date()) + ".png"
    }
    
    func save(drawing: PKDrawing) {
        let png = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale).pngData()
        document?.pngNote = png
        if let document = document {
            document.save(to: document.fileURL, for: .forOverwriting)
        } else {
            let path = iCloudURL.appendingPathComponent(fileName)
            document = NoteDocument(fileURL: path)
            document?.save(to: path, for: .forCreating)
        }
    }
    
    func appendDrawing(drawing: PKDrawing) {
        let png = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale).pngData()
        try! png?.write(to: iCloudURL)
        
//        let result = try! FileManager.default.contentsOfDirectory(atPath: FileManager.default.url(forUbiquityContainerIdentifier: nil)!.appendingPathComponent("Documents").path)
//        print(result)
    }
}
