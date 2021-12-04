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
    @Published var publishedNoteDocuments = [NoteDocument]()
    private var noteDocuments = [NoteDocument]() {
        didSet {
            if counter <= noteDocuments.count {
                publishedNoteDocuments = noteDocuments.sorted { $0.fileModificationDate ?? Date() < $1.fileModificationDate ?? Date() }
                noteDocuments.removeAll()
            }
        }
    }
    
    private var counter = 0
    
    init() {
        openAllDocuments()
    }
    
    private func openAllDocuments() {
        guard let iCloudInboxUrl = FilePath.iCloudInboxUrl,
              let allFileNames = try? FileManager.default.contentsOfDirectory(atPath: iCloudInboxUrl.path) else { return }
        let drawingFileNames = allFileNames.filter { $0.hasSuffix(".plist") }.sorted(by: <)
        counter = drawingFileNames.count
        
        drawingFileNames.forEach { [weak self] filename in
            open(filename: filename) { drawing in
                DispatchQueue.main.async {
                    self?.noteDocuments.append(drawing)
                }
            }
        }
    }
    
    private func open(filename: String, comp: @escaping (NoteDocument) -> Void) {
        guard let iCloudInboxUrl = FilePath.iCloudInboxUrl else { return }
        let url = iCloudInboxUrl.appendingPathComponent(filename)
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
    
    func update() {
        openAllDocuments()
    }
}
