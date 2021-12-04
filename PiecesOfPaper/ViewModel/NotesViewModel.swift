//
//  NotesViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import PencilKit

final class NotesViewModel: ObservableObject {
    @Published var publishedNoteDocuments = [NoteDocument]()
    @Published var isLoaded = false
    private var noteDocuments = [NoteDocument]() {
        didSet {
            if counter <= noteDocuments.count {
                publishedNoteDocuments = noteDocuments.sorted { $0.entity.updatedDate < $1.entity.updatedDate }
                isLoaded = true
                noteDocuments.removeAll()
            }
        }
    }
    
    enum TargetDirectory: String {
        case inbox, archived, all
    }
    
    private var directory: TargetDirectory
    private var counter = 0
    
    init(targetDirectory: TargetDirectory) {
        self.directory = targetDirectory
    }
    
    func fetch() {
        openDocuments()
    }
    
    private func openDocuments() {
        let urls = getFileUrl()
        urls.forEach { [weak self] url in
            open(fileUrl: url) { document in
                DispatchQueue.main.async {
                    self?.noteDocuments.append(document)
                }
            }
        }
    }
    
    private func getFileUrl() -> [URL] {
        guard let iCloudInboxUrl = FilePath.iCloudInboxUrl,
              var inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: iCloudInboxUrl.path),
              let iCloudArchivedUrl = FilePath.iCloudArchivedUrl,
              var archivedFileNames = try? FileManager.default.contentsOfDirectory(atPath: iCloudArchivedUrl.path) else { return [] }
        
        inboxFileNames = inboxFileNames.filter { $0.hasSuffix(".plist") }
        archivedFileNames = archivedFileNames.filter { $0.hasSuffix(".plist") }
        
        switch directory {
        case .inbox:
            counter = inboxFileNames.count
            return inboxFileNames.map { iCloudInboxUrl.appendingPathComponent($0) }
        case .archived:
            counter = archivedFileNames.count
            return archivedFileNames.map { iCloudArchivedUrl.appendingPathComponent($0) }
        case .all:
            counter = inboxFileNames.count + archivedFileNames.count
            let inboxUrls = inboxFileNames.map { iCloudInboxUrl.appendingPathComponent($0) }
            let archivedUrls = archivedFileNames.map { iCloudArchivedUrl.appendingPathComponent($0) }
            return inboxUrls + archivedUrls
        }
    }
    
    private func open(fileUrl: URL, comp: @escaping (NoteDocument) -> Void) {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else { return }
        let document = NoteDocument(fileURL: fileUrl)
        
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
        isLoaded = false
        openDocuments()
    }
}
