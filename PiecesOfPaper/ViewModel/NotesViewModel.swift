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
    @Published var noteDocuments = [NoteDocument]()
    private var localNoteDocuments = [NoteDocument]()
    
    init() {
        temp()
    }
    
    // TODO: ちゃんとやる
    func asyncTemp(filename: String, comp: @escaping (NoteDocument) -> Void) {
        DispatchQueue.global().async {
            let url = FilePath.iCloudURL.appendingPathComponent(filename)
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let document = NoteDocument(fileURL: url)
            document.open() { success in
                if success {
                    comp(document)
                    document.close()
                } else {
                    fatalError("could not open document")
                }
            }
        }
    }
    
    func update() {
        localNoteDocuments.removeAll()
        temp()
    }
    
    // TODO: ちゃんとやる
    private func temp() {
        let allFileNames = try! FileManager.default.contentsOfDirectory(atPath: FilePath.iCloudURL.path)
        let drawingFileNames = allFileNames.filter { $0.hasSuffix(".pkdrawing") }
        
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        
        drawingFileNames.forEach { filename in
            dispatchGroup.enter()
            dispatchQueue.async(group: dispatchGroup) { [weak self] in
                self?.asyncTemp(filename: filename) { drawing in
                    defer { dispatchGroup.leave() }
                    self?.localNoteDocuments.append(drawing)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.noteDocuments = self.localNoteDocuments.sorted { $0.fileModificationDate ?? Date() > $1.fileModificationDate ?? Date() }
        }
    }

}
