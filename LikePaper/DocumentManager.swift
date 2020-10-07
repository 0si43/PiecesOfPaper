//
//  DocumentManager.swift
//  LikePaper
//
//  Created by nakajima on 2020/09/29.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import Foundation
import PencilKit

protocol DocumentManagerDelegate: AnyObject {
    var didDocumentOpen: Bool { get set }
}

struct DocumentManager {
    weak var delegate: DocumentManagerDelegate?
    
    var oldURLPath: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first!
    }
    
    // formmat in ver 1.0.0 ~ 1.2.0
    var oldURL: URL {
        return oldURLPath.appendingPathComponent("Like_a_Paper.data")
    }
    
    var renamedOldURL: URL {
        return oldURLPath.appendingPathComponent("Like_a_Paper_v1format.data")
    }
    
    var saveURL: URL {
        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)!
            .appendingPathComponent("Documents")
            .appendingPathComponent("drawings.plist")
        return url
    }
    
    var document: Document!
    var drawings: [PKDrawing] {
        get { document.dataModel.drawings }
        set { document.dataModel.drawings = newValue }
    }
    
    init(delegate: DocumentManagerDelegate) {
        self.delegate = delegate
        document = Document(fileURL: saveURL)
        migrateICloudIfNeeded()
        document.open { [self]success in
            if success {
                self.delegate?.didDocumentOpen = true
                print("open success")
            } else {
                print("open failure")
            }
        }
    }
    
    private mutating func migrateICloudIfNeeded() {
        guard FileManager.default.fileExists(atPath: oldURL.path),
              !FileManager.default.fileExists(atPath: saveURL.path) else { return }
        let dataModel = DataModel(url: oldURL)
        try? FileManager.default.moveItem(atPath: oldURL.path, toPath: renamedOldURL.path)
        document.dataModel = dataModel
        document.save(to: saveURL, for: .forCreating)
    }
    
    func save() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        guard let didDocumentOpen = delegate?.didDocumentOpen, didDocumentOpen else { return }
        document.save(to: saveURL, for: .forOverwriting) { success in
            let result = success ? "success" : "failure"
            print("save " + result)
        }
    }
    
    func autosave() {
        guard let didDocumentOpen = delegate?.didDocumentOpen, didDocumentOpen else { return }
        document.updateChangeCount(.done)
        print("autosave")
    }
}
