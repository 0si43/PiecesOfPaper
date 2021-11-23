//
//  CanvasViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

final class CanvasViewModel: ObservableObject, DocumentManagerDelegate {
    var didDocumentOpen = false
    private var documentManager: DocumentManager!
    var iCloudURL: URL {
        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)!
            .appendingPathComponent("Documents")
        return url
    }
    
    func save(drawing: PKDrawing) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ssSSSS"
        let string = dateFormatter.string(from: Date())
        print(string)
        let path = iCloudURL.appendingPathComponent(string + ".png")
        let png = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale).pngData()
        try! png?.write(to: path)
    }
    
    func appendDrawing(drawing: PKDrawing) {
        let png = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale).pngData()
        try! png?.write(to: iCloudURL)        
        
//        let result = try! FileManager.default.contentsOfDirectory(atPath: FileManager.default.url(forUbiquityContainerIdentifier: nil)!.appendingPathComponent("Documents").path)
//        print(result)
    }
}
