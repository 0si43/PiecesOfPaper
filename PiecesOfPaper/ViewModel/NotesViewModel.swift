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
    var didFirstFetchRequest = false
    enum TargetDirectory: String {
        case inbox, archived, all
    }

    private var directory: TargetDirectory
    private var counter = 0
    private var noteDocuments = [NoteDocument]() {
        didSet {
            if counter <= noteDocuments.count {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.publishedNoteDocuments = self.noteDocuments.sorted { $0.entity.updatedDate < $1.entity.updatedDate }
                    self.isLoaded = true
                    self.counter = 0
                }
            }
        }
    }

    init(targetDirectory: TargetDirectory) {
        self.directory = targetDirectory
    }

    func fetch() {
        openDocuments()
    }

    private func openDocuments() {
        let urls = getFileUrl()
        guard !urls.isEmpty else {
            publishedNoteDocuments = [NoteDocument]()
            isLoaded = true
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.counter = urls.count
        }
        urls.forEach { [weak self] url in
            open(fileUrl: url) { document in
                self?.noteDocuments.append(document)
            }
        }
    }

    private func getFileUrl() -> [URL] {
        guard let iCloudInboxUrl = FilePath.iCloudInboxUrl,
              var inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: iCloudInboxUrl.path),
              let iCloudArchivedUrl = FilePath.iCloudArchivedUrl,
              var archivedFileNames =
                try? FileManager.default.contentsOfDirectory(atPath: iCloudArchivedUrl.path) else { return [] }

        inboxFileNames = inboxFileNames.filter { $0.hasSuffix(".plist") }
        archivedFileNames = archivedFileNames.filter { $0.hasSuffix(".plist") }

        switch directory {
        case .inbox:
            return inboxFileNames.map { iCloudInboxUrl.appendingPathComponent($0) }
        case .archived:
            return archivedFileNames.map { iCloudArchivedUrl.appendingPathComponent($0) }
        case .all:
            let inboxUrls = inboxFileNames.map { iCloudInboxUrl.appendingPathComponent($0) }
            let archivedUrls = archivedFileNames.map { iCloudArchivedUrl.appendingPathComponent($0) }
            return inboxUrls + archivedUrls
        }
    }

    private func open(fileUrl: URL, comp: @escaping (NoteDocument) -> Void) {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else { return }
        let document = NoteDocument(fileURL: fileUrl)

        document.open { success in
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
        noteDocuments.removeAll()
        openDocuments()
    }

    func archive(document: NoteDocument) {
        guard let iCloudArchivedUrl = FilePath.iCloudArchivedUrl else { return }
        let toUrl = iCloudArchivedUrl.appendingPathComponent(document.fileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: document.fileURL, to: toUrl)
        } catch {
            print("Could not archive: ", error.localizedDescription)
        }

        publishedNoteDocuments = Array(noteDocuments.drop { $0.entity.id == document.entity.id })
    }

    func unarchive(document: NoteDocument) {
        guard let iCloudInboxUrl = FilePath.iCloudInboxUrl else { return }
        let toUrl = iCloudInboxUrl.appendingPathComponent(document.fileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: document.fileURL, to: toUrl)
        } catch {
            print("Could not unarchive: ", error.localizedDescription)
        }

        publishedNoteDocuments = Array(noteDocuments.drop { $0.entity.id == document.entity.id })
    }

    func getTagToNote(document: NoteDocument) -> [TagEntity] {
        let tagModel = TagModel()
        let tags = tagModel.tags
        return tags.filter {
            document.entity.tags.contains($0.name)
        }
    }
}
