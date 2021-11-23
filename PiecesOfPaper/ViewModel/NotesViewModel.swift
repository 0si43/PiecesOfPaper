//
//  NotesViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

final class NotesViewModel: ObservableObject, DocumentManagerDelegate {
    var didDocumentOpen = false
    @Published var drawings = [PKDrawing]()
    private var documentManager: DocumentManager!
    private var didSet = false
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setDrawings),
                                               name: UIDocument.stateChangedNotification,
                                               object: nil)
        documentManager = DocumentManager(delegate: self)
    }
    
    @objc func setDrawings() {
        guard !didSet else { return }
        self.drawings = documentManager.drawings
        didSet = true
    }
    
    func appendDrawing(drawing: PKDrawing) {
        guard didDocumentOpen else { return }
        documentManager.drawings.append(drawing)
        documentManager.save()
    }
}
