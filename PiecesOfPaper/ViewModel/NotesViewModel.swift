//
//  NotesViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

final class NotesViewModel: ObservableObject {
    @Published var drawings = [PKDrawing]()
    private var localDrawings = [PKDrawing]()
    
    init() {
        let allFileNames = try! FileManager.default.contentsOfDirectory(atPath: FilePath.iCloudURL.path)
        let drawingFileNames = allFileNames.filter { $0.hasSuffix(".drawing") }
        
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        
        drawingFileNames.forEach { filename in
            dispatchGroup.enter()
            dispatchQueue.async(group: dispatchGroup) { [weak self] in
                self?.asyncTemp(filename: filename) { drawing in
                    defer { dispatchGroup.leave() }
                    self?.localDrawings.append(drawing)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.drawings = self.localDrawings
        }
    }
    
    func asyncTemp(filename: String, comp: @escaping (PKDrawing) -> Void) {
        DispatchQueue.global().async {
            let url = FilePath.iCloudURL.appendingPathComponent(filename)
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let document = NoteDocument(fileURL: url)
            document.open() { success in
                if success {
                    comp(document.drawing)
                } else {
                    fatalError("could not open document")
                }
            }
        }
    }
    
    func update() {
        localDrawings.removeAll()
        let allFileNames = try! FileManager.default.contentsOfDirectory(atPath: FilePath.iCloudURL.path)
        let drawingFileNames = allFileNames.filter { $0.hasSuffix(".drawing") }
        
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        
        drawingFileNames.forEach { filename in
            dispatchGroup.enter()
            dispatchQueue.async(group: dispatchGroup) { [weak self] in
                self?.asyncTemp(filename: filename) { drawing in
                    defer { dispatchGroup.leave() }
                    self?.localDrawings.append(drawing)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.drawings = self.localDrawings
        }
    }
}
