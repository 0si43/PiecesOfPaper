//
//  ViewModel.swift
//  PiecesOfPaper
//
//  Created by nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi nakajima. All rights reserved.
//

import Foundation
import PencilKit

class ViewModel: ObservableObject, DocumentManagerDelegate {
    var didDocumentOpen = false
    @Published var drawings = [PKDrawing]()
    private var documentManager: DocumentManager!
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(save),
                                               name: UIDocument.stateChangedNotification,
                                               object: nil)
        documentManager = DocumentManager(delegate: self)
    }
    
    @objc func save() {
        self.drawings = documentManager.drawings
    }
}
