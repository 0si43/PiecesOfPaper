//
//  NotesViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var displayNoteDocuments = [NoteDocument]()
    // Set initial value to true to show loading state when view appears
    @Published var isLoading = true
    private var noteDocuments = [NoteDocument]()
    enum TargetDirectory: String {
        case inbox, archived, all
    }

    private var directory: TargetDirectory
    var isTargetDirectoryInbox: Bool {
        directory == .inbox
    }

    var isTargetDirectoryArchived: Bool {
        directory == .archived
    }

    private var listOrderStore: ListOrderStoreProtocol
    var listOrder: ListOrder {
        didSet {
            listOrderStore.set(directoryName: directory.rawValue, listOrder: listOrder)
        }
    }

    private func saveConditionInDevice() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(listOrder) else { return }
        UserDefaults.standard.set(data, forKey: "listOrder(" + directory.rawValue + ")")
    }

    init(targetDirectory: TargetDirectory, listOrderStore: ListOrderStoreProtocol = ListOrderStore()) {
        self.directory = targetDirectory
        self.listOrderStore = listOrderStore
        self.listOrder = listOrderStore.get(directoryName: directory.rawValue)
    }

    // MARK: - fetch
    
    func fetch() async {
        defer {
            isLoading = false
        }
        isLoading = true
        let (added, removed) = fetchChangedFileUrls()
        await updateDocuments(addedUrls: added, removedUrls: removed)
        display()
    }

    private var cachedUrls: [URL] = []
    private func fetchChangedFileUrls() -> (addedUrls: [URL], removedUrls: [URL]) {
        let latestUrls = getFileUrls()
        let oldSet = Set(cachedUrls)
        let latestSet = Set(latestUrls)
        let added = latestSet.subtracting(oldSet)
        let removed = oldSet.subtracting(latestSet)
        return (Array(added), Array(removed))
    }

    private func updateDocuments(addedUrls: [URL], removedUrls: [URL]) async {
        await withTaskGroup(of: Void.self) { [weak self] group in
            for url in addedUrls {
                group.addTask {
                    await self?.open(fileUrl: url)
                }
            }
        }

        removedUrls.forEach { url in
            if let index = noteDocuments.firstIndex(where: { $0.fileURL == url }) {
                noteDocuments.remove(at: index)
            }
        }
    }

    private func display() {
        displayNoteDocuments = reorderDocuments
    }

    // MARK: - helper methods for fetch
    
    /// get file path array (iCloud or local storage)
    private func getFileUrls() -> [URL] {
        guard let inboxUrl = FilePath.inboxUrl,
              var inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: inboxUrl.path),
              let archivedUrl = FilePath.archivedUrl,
              var archivedFileNames =
                try? FileManager.default.contentsOfDirectory(atPath: archivedUrl.path) else { return [] }

        inboxFileNames = inboxFileNames.filter { $0.hasSuffix(".plist") }
        archivedFileNames = archivedFileNames.filter { $0.hasSuffix(".plist") }

        switch directory {
        case .inbox:
            return inboxFileNames.map { inboxUrl.appendingPathComponent($0) }
        case .archived:
            return archivedFileNames.map { archivedUrl.appendingPathComponent($0) }
        case .all:
            let inboxUrls = inboxFileNames.map { inboxUrl.appendingPathComponent($0) }
            let archivedUrls = archivedFileNames.map { archivedUrl.appendingPathComponent($0) }
            return inboxUrls + archivedUrls
        }
    }

    private func open(fileUrl: URL) async {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else { return }
        let document = NoteDocument(fileURL: fileUrl)
        let success = await document.open()
        if success {
            noteDocuments.append(document)
        } else {
            // FIXME: - somehow notify failure to user
        }
        await document.close()
    }

    func update() {
//        noteDocuments.removeAll()
//        openDocuments()
    }

    private var reorderDocuments: [NoteDocument] {
        var notes = noteDocuments
        listOrder.filterBy.forEach { filteringTag in
            notes = notes.filter { $0.entity.tags.contains(filteringTag) }
        }
        switch listOrder.sortOrder {
        case .ascending:
            switch listOrder.sortBy {
            case .updatedDate:
                notes = notes.sorted { $0.entity.updatedDate < $1.entity.updatedDate }
            case .createdDate:
                notes = notes.sorted { $0.entity.createdDate < $1.entity.createdDate }
            }
        case .descending:
            switch listOrder.sortBy {
            case .updatedDate:
                notes = notes.sorted { $0.entity.updatedDate > $1.entity.updatedDate }
            case .createdDate:
                notes = notes.sorted { $0.entity.createdDate > $1.entity.createdDate }
            }
        }
        return notes
    }

    // MARK: - action

    func duplicate(_ document: NoteDocument) {
        guard let inboxUrl = FilePath.inboxUrl,
              let archivedUrl = FilePath.archivedUrl else { return }

        let directory = isTargetDirectoryArchived ? archivedUrl : inboxUrl
        let newUrl = directory.appendingPathComponent(FilePath.fileName)
        let entity = NoteEntity(drawing: document.entity.drawing)
        let newDocument = NoteDocument(fileURL: newUrl, entity: entity)
        newDocument.save(to: newUrl, for: .forCreating) { [weak self] success in
            if success {
                self?.noteDocuments.append(newDocument)
                self?.display()
            }
        }
    }

    func delete(_ document: NoteDocument) {
        try? FileManager.default.removeItem(at: document.fileURL)
        noteDocuments = Array(noteDocuments.filter { $0.entity.id != document.entity.id })
        display()
    }

    func archive(_ document: NoteDocument) {
        guard let archivedUrl = FilePath.archivedUrl else { return }
        let toUrl = archivedUrl.appendingPathComponent(document.fileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: document.fileURL, to: toUrl)
        } catch {
            print("Could not archive: ", error.localizedDescription)
        }

        noteDocuments = Array(noteDocuments.filter { $0.entity.id != document.entity.id })
        display()
    }

    func unarchive(_ document: NoteDocument) {
        guard let inboxUrl = FilePath.inboxUrl else { return }
        let toUrl = inboxUrl.appendingPathComponent(document.fileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: document.fileURL, to: toUrl)
        } catch {
            print("Could not unarchive: ", error.localizedDescription)
        }

        noteDocuments = Array(noteDocuments.filter { $0.entity.id != document.entity.id })
        display()
    }

    func getTagToNote(document: NoteDocument) -> [TagEntity] {
        let tagModel = TagModel()
        let tags = tagModel.tags
        return tags.filter {
            document.entity.tags.contains($0)
        }
    }

    func allArchive() {
        noteDocuments.forEach { archive($0) }
        display()
    }

    func allUnarchive() {
        noteDocuments.forEach { unarchive($0) }
        display()
    }
}
