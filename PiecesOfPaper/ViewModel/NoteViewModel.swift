//
//  NoteViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

@MainActor
final class NoteViewModel: ObservableObject {
    @Published var displayNoteDocuments = [NoteDocument]()
    @Published var isShowLoading = true
    @Published var documentToShare: NoteDocument?
    @Published var documentToTag: NoteDocument?
    private var noteDocuments = [NoteDocument]()

    var isTargetDirectoryInbox: Bool {
        documentStore.directory == .inbox
    }

    var isTargetDirectoryArchived: Bool {
        documentStore.directory == .archived
    }

    private var documentStore: DocumentStoreProtocol
    private var listOrderStore: ListOrderStoreProtocol
    var listOrder: ListOrder {
        didSet {
            listOrderStore.set(directoryName: documentStore.directory.rawValue, listOrder: listOrder)
            displayReorderDocuments()
        }
    }

    init(documentStore: DocumentStoreProtocol, listOrderStore: ListOrderStoreProtocol = ListOrderStore()) {
        self.documentStore = documentStore
        self.listOrderStore = listOrderStore
        self.listOrder = listOrderStore.get(directoryName: documentStore.directory.rawValue)
    }

    // MARK: - fetch

    func incrementalFetch() async {
        defer {
            isShowLoading = false
        }
        isShowLoading = true
        let (added, removed) = fetchChangedFileUrls()
        // FIXME: - デバッグ終わったら消す
        print("added: \(added.count), removed: \(removed.count)")
        await updateDocuments(addedUrls: added, removedUrls: removed)
        displayReorderDocuments()
    }

    func reload() async {
        noteDocuments.removeAll()
        cachedUrls.removeAll()
        await incrementalFetch()
    }

    private var cachedUrls: [URL] = []
    private func fetchChangedFileUrls() -> (addedUrls: [URL], removedUrls: [URL]) {
        let latestUrls = documentStore.getFileUrls()
        let oldSet = Set(cachedUrls)
        let latestSet = Set(latestUrls)
        let added = latestSet.subtracting(oldSet)
        let removed = oldSet.subtracting(latestSet)
        cachedUrls = latestUrls
        return (Array(added), Array(removed))
    }

    private func updateDocuments(addedUrls: [URL], removedUrls: [URL]) async {
        do {
            noteDocuments += try await withThrowingTaskGroup(of: NoteDocument.self) { [weak self] group in
                guard let self = self else { return [] }
                var documents: [NoteDocument] = []
                for url in addedUrls {
                    group.addTask {
                        try await self.documentStore.open(fileUrl: url)
                    }
                }

                for try await document in group {
                    documents.append(document)
                }

                return documents
            }
        } catch {
            // FIXME: -
        }

        removedUrls.forEach { url in
            if let index = noteDocuments.firstIndex(where: { $0.fileURL == url }) {
                noteDocuments.remove(at: index)
            }
        }
    }

    private func displayReorderDocuments() {
        displayNoteDocuments = reorderDocuments
    }

    // MARK: - helper methods for fetch

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
                self?.cachedUrls.append(newUrl)
                self?.noteDocuments.append(newDocument)
                self?.displayNoteDocuments.insert(newDocument, at: 0)
            }
        }
    }

    func delete(_ document: NoteDocument) {
        do {
            try FileManager.default.removeItem(at: document.fileURL)
            cachedUrls = cachedUrls.filter { $0 != document.fileURL }
            noteDocuments = Array(noteDocuments.filter { $0.entity.id != document.entity.id })
            displayNoteDocuments = Array(displayNoteDocuments.filter { $0.entity.id != document.entity.id })
        } catch {
            // FIXME: - need alert
        }
    }

    func archive(_ document: NoteDocument) {
        guard let archivedUrl = FilePath.archivedUrl else { return }
        let toUrl = archivedUrl.appendingPathComponent(document.fileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: document.fileURL, to: toUrl)
        } catch {
            print("Could not archive: ", error.localizedDescription)
        }

        cachedUrls = cachedUrls.filter { $0 != document.fileURL }
        noteDocuments = Array(noteDocuments.filter { $0.entity.id != document.entity.id })
        displayNoteDocuments = Array(displayNoteDocuments.filter { $0.entity.id != document.entity.id })
    }

    func unarchive(_ document: NoteDocument) {
        guard let inboxUrl = FilePath.inboxUrl else { return }
        let toUrl = inboxUrl.appendingPathComponent(document.fileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: document.fileURL, to: toUrl)
        } catch {
            print("Could not unarchive: ", error.localizedDescription)
        }

        cachedUrls = cachedUrls.filter { $0 != document.fileURL }
        noteDocuments = Array(noteDocuments.filter { $0.entity.id != document.entity.id })
        displayNoteDocuments = Array(displayNoteDocuments.filter { $0.entity.id != document.entity.id })
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
        displayReorderDocuments()
    }

    func allUnarchive() {
        noteDocuments.forEach { unarchive($0) }
        displayReorderDocuments()
    }
}
