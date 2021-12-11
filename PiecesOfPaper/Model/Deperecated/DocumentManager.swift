//
//  DocumentManager.swift
//  LikePaper
//
//  Created by Nakajima on 2020/09/29.
//  Copyright © 2020 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

protocol DocumentManagerDelegate: AnyObject {
    var didDocumentOpen: Bool { get set }
}

struct DocumentManager {
    weak var delegate: DocumentManagerDelegate?

    var documentDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first!
    }

    // formmat in ver 1.0.0 ~ 1.2.0
    var oldURL: URL {
        documentDirectory.appendingPathComponent("Like_a_Paper.data")
    }

    var renamedOldURL: URL {
        documentDirectory.appendingPathComponent("Like_Paper_v1format.plist")
    }

    var saveURL: URL {
        isiCloudEnabled ? iCloudURL : deviceURL
    }

    var deviceURL: URL {
        documentDirectory.appendingPathComponent("drawings.plist")
    }

    var iCloudURL: URL {
        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)!
            .appendingPathComponent("Documents")
            .appendingPathComponent("drawings.plist")
        return url
    }

    private var isiCloudEnabled: Bool {
        (FileManager.default.ubiquityIdentityToken != nil)
    }

    var document: Document!
    var drawings: [PKDrawing] {
        get { document.dataModel.drawings }
        set { document.dataModel.drawings = newValue }
    }

    init(delegate: DocumentManagerDelegate) {
        self.delegate = delegate
        document = Document(fileURL: saveURL)

        if FileManager.default.fileExists(atPath: saveURL.path) {
            openDocument()
        } else {
            if FileManager.default.fileExists(atPath: oldURL.path) {
                migrateFileIfNeeded()
            } else {
                createNewDocument() // new install after version 2.0
            }
        }
    }

    private mutating func migrateFileIfNeeded() {
        guard FileManager.default.fileExists(atPath: oldURL.path),
              !FileManager.default.fileExists(atPath: saveURL.path) else { return }
        let dataModel = DataModel(url: oldURL)
        try? FileManager.default.moveItem(atPath: oldURL.path, toPath: renamedOldURL.path)
        document.dataModel = dataModel
        document.save(to: saveURL, for: .forCreating) {[self] success in
            if success {
                print("migrate: success")
                self.openDocument()
            } else {
                print("migrate: failure")
                fatalError("could not maigrate old file")
            }
        }
    }

    private mutating func createNewDocument() {
        guard !FileManager.default.fileExists(atPath: saveURL.path) else { return }
        document.dataModel = DataModel()
        document.save(to: saveURL, for: .forCreating) {[self] success in
            if success {
                print("new document create: success")
                self.openDocument()
            } else {
                print("new document create:  failure")
                fatalError("could not create new document")
            }
        }
    }

    private func openDocument() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        document.open { [self] success in
            if success {
                self.delegate?.didDocumentOpen = true
                print("open success")
            } else {
                print("open failure")
                fatalError("could not open document")
            }
        }
    }

    func save() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        guard let didDocumentOpen = delegate?.didDocumentOpen, didDocumentOpen else { return }
        document.save(to: saveURL, for: .forOverwriting) { success in
            let result = success ? "success" : "failure"
            print("save: " + result)
        }
    }

    func autosave() {
        guard let didDocumentOpen = delegate?.didDocumentOpen, didDocumentOpen else { return }
        document.updateChangeCount(.done)
        print("autosave")
    }

    // The winner choose by iCloud will be winner.
    // Maybe simply based on modificationDate. A later saved is a winner.
    func resolveConflict() {
        do {
            let currentVersion = NSFileVersion.currentVersionOfItem(at: saveURL)
            try NSFileVersion.removeOtherVersionsOfItem(at: saveURL)
            currentVersion?.isResolved = true
        } catch {
            print("failed delete conflict files")
        }
    }
}
