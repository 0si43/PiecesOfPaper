//
//  NoteStore.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

@Observable
@MainActor
final class NoteStore {
    // MARK: - Primary data (Single Source of Truth)
    private(set) var inboxDocuments = [NoteDocument]()
    private(set) var archivedDocuments = [NoteDocument]()

    // MARK: - Sort & filter settings (auto-persist on change)
    var inboxListOrder: ListOrder {
        didSet {
            preferenceRepository.setListOrder(directoryName: NoteDirectory.inbox.rawValue, listOrder: inboxListOrder)
        }
    }
    var archivedListOrder: ListOrder {
        didSet {
            preferenceRepository.setListOrder(directoryName: NoteDirectory.archived.rawValue, listOrder: archivedListOrder)
        }
    }

    // MARK: - UI state
    var isLoading = true
    var showCanvasView = false
    var showAlert = false
    var alertType: AlertType?
    var documentToShare: NoteDocument?
    var documentToTag: NoteDocument?

    enum AlertType {
        case iCloudDenied, archive, error(Error)
    }

    // MARK: - Dependencies
    private let noteRepository: NoteRepositoryProtocol
    private let preferenceRepository: PreferenceRepositoryProtocol

    // MARK: - Cache for incremental fetch
    private var inboxCachedUrls: [URL] = []
    private var archivedCachedUrls: [URL] = []

    init(noteRepository: NoteRepositoryProtocol = NoteRepository(),
         preferenceRepository: PreferenceRepositoryProtocol = PreferenceRepository()) {
        self.noteRepository = noteRepository
        self.preferenceRepository = preferenceRepository
        self.inboxListOrder = preferenceRepository.getListOrder(directoryName: NoteDirectory.inbox.rawValue)
        self.archivedListOrder = preferenceRepository.getListOrder(directoryName: NoteDirectory.archived.rawValue)
    }

    // MARK: - Computed display documents (replaces dual-management)

    var displayInboxDocuments: [NoteDocument] {
        reorderDocuments(inboxDocuments, listOrder: inboxListOrder)
    }

    var displayArchivedDocuments: [NoteDocument] {
        reorderDocuments(archivedDocuments, listOrder: archivedListOrder)
    }

    func displayDocuments(for directory: NoteDirectory) -> [NoteDocument] {
        switch directory {
        case .inbox: displayInboxDocuments
        case .archived: displayArchivedDocuments
        }
    }

    func listOrder(for directory: NoteDirectory) -> ListOrder {
        switch directory {
        case .inbox: inboxListOrder
        case .archived: archivedListOrder
        }
    }

    func setListOrder(_ listOrder: ListOrder, for directory: NoteDirectory) {
        switch directory {
        case .inbox: inboxListOrder = listOrder
        case .archived: archivedListOrder = listOrder
        }
    }

    // MARK: - Fetch

    func incrementalFetch(directory: NoteDirectory) async {
        defer { isLoading = false }
        isLoading = true
        let (added, removed) = fetchChangedFileUrls(directory: directory)
        await updateDocuments(addedUrls: added, removedUrls: removed, directory: directory)
    }

    func reload(directory: NoteDirectory) async {
        switch directory {
        case .inbox:
            inboxDocuments.removeAll()
            inboxCachedUrls.removeAll()
        case .archived:
            archivedDocuments.removeAll()
            archivedCachedUrls.removeAll()
        }
        await incrementalFetch(directory: directory)
    }

    private func fetchChangedFileUrls(directory: NoteDirectory) -> (addedUrls: [URL], removedUrls: [URL]) {
        let latestUrls = noteRepository.getFileUrls(directory: directory)
        let cachedUrls = directory == .inbox ? inboxCachedUrls : archivedCachedUrls
        let oldSet = Set(cachedUrls)
        let latestSet = Set(latestUrls)
        let added = latestSet.subtracting(oldSet)
        let removed = oldSet.subtracting(latestSet)

        switch directory {
        case .inbox: inboxCachedUrls = latestUrls
        case .archived: archivedCachedUrls = latestUrls
        }

        return (Array(added), Array(removed))
    }

    private func updateDocuments(addedUrls: [URL], removedUrls: [URL], directory: NoteDirectory) async {
        let (newDocuments, failedUrls) = await withTaskGroup(
            of: (url: URL, document: NoteDocument?).self
        ) { group -> ([NoteDocument], [URL]) in
            for url in addedUrls {
                group.addTask {
                    (url, try? await self.noteRepository.open(fileUrl: url))
                }
            }

            var documents: [NoteDocument] = []
            var failed: [URL] = []
            for await result in group {
                if let document = result.document {
                    documents.append(document)
                } else {
                    failed.append(result.url)
                }
            }

            return (documents, failed)
        }

        switch directory {
        case .inbox:
            inboxDocuments += newDocuments
            // Drop failed URLs from the cache so the next fetch retries them
            inboxCachedUrls.removeAll { failedUrls.contains($0) }
            removedUrls.forEach { url in
                inboxDocuments.removeAll { $0.fileURL == url }
            }
        case .archived:
            archivedDocuments += newDocuments
            archivedCachedUrls.removeAll { failedUrls.contains($0) }
            removedUrls.forEach { url in
                archivedDocuments.removeAll { $0.fileURL == url }
            }
        }

        if !failedUrls.isEmpty {
            alertType = .error(NoteStoreError.openFailed(count: failedUrls.count))
            showAlert = true
        }
    }

    // MARK: - Reorder helper

    private func reorderDocuments(_ notes: [NoteDocument], listOrder: ListOrder) -> [NoteDocument] {
        var filtered = notes
        listOrder.filterBy.forEach { filteringTag in
            filtered = filtered.filter { $0.entity.tags.contains(filteringTag) }
        }
        switch listOrder.sortOrder {
        case .ascending:
            switch listOrder.sortBy {
            case .updatedDate:
                filtered.sort { $0.entity.updatedDate < $1.entity.updatedDate }
            case .createdDate:
                filtered.sort { $0.entity.createdDate < $1.entity.createdDate }
            }
        case .descending:
            switch listOrder.sortBy {
            case .updatedDate:
                filtered.sort { $0.entity.updatedDate > $1.entity.updatedDate }
            case .createdDate:
                filtered.sort { $0.entity.createdDate > $1.entity.createdDate }
            }
        }
        return filtered
    }

    // MARK: - Data operations

    func duplicate(_ document: NoteDocument, in directory: NoteDirectory) {
        noteRepository.duplicate(document: document, in: directory) { [weak self] newDocument in
            guard let self else { return }
            guard let newDocument else {
                self.alertType = .error(NoteStoreError.saveFailed)
                self.showAlert = true
                return
            }
            switch directory {
            case .inbox:
                self.inboxCachedUrls.append(newDocument.fileURL)
                self.inboxDocuments.append(newDocument)
            case .archived:
                self.archivedCachedUrls.append(newDocument.fileURL)
                self.archivedDocuments.append(newDocument)
            }
        }
    }

    func delete(_ document: NoteDocument) {
        do {
            try noteRepository.delete(fileUrl: document.fileURL)
            removeDocumentFromArrays(document)
        } catch {
            alertType = .error(NoteStoreError.deleteFailed)
            showAlert = true
        }
    }

    func archive(_ document: NoteDocument) {
        do {
            let newUrl = try noteRepository.move(fileUrl: document.fileURL, to: .archived)
            // Remove from inbox
            inboxCachedUrls.removeAll { $0 == document.fileURL }
            inboxDocuments.removeAll { $0.entity.id == document.entity.id }
            // Add to archived
            let archivedDocument = NoteDocument(fileURL: newUrl, entity: document.entity)
            archivedCachedUrls.append(newUrl)
            archivedDocuments.append(archivedDocument)
        } catch {
            print("Could not archive: ", error.localizedDescription)
        }
    }

    func unarchive(_ document: NoteDocument) {
        do {
            let newUrl = try noteRepository.move(fileUrl: document.fileURL, to: .inbox)
            // Remove from archived
            archivedCachedUrls.removeAll { $0 == document.fileURL }
            archivedDocuments.removeAll { $0.entity.id == document.entity.id }
            // Add to inbox
            let inboxDocument = NoteDocument(fileURL: newUrl, entity: document.entity)
            inboxCachedUrls.append(newUrl)
            inboxDocuments.append(inboxDocument)
        } catch {
            print("Could not unarchive: ", error.localizedDescription)
        }
    }

    func allArchive() {
        let documents = inboxDocuments
        documents.forEach { archive($0) }
    }

    func allUnarchive() {
        let documents = archivedDocuments
        documents.forEach { unarchive($0) }
    }

    // MARK: - Tag operations on notes

    func addTag(_ tag: TagEntity, to document: NoteDocument) {
        document.entity.tags.append(tag)
        noteRepository.save(document: document) { [weak self] success in
            guard let self else { return }
            if success {
                self.updateDocumentInArray(document)
            } else {
                document.entity.tags.removeAll { $0 == tag }
                self.alertType = .error(NoteStoreError.saveFailed)
                self.showAlert = true
            }
        }
    }

    func removeTag(_ tag: TagEntity, from document: NoteDocument) {
        document.entity.tags.removeAll { $0 == tag }
        noteRepository.save(document: document) { [weak self] success in
            guard let self else { return }
            if success {
                self.updateDocumentInArray(document)
            } else {
                document.entity.tags.append(tag)
                self.alertType = .error(NoteStoreError.saveFailed)
                self.showAlert = true
            }
        }
    }

    // MARK: - Note lookup & write-back

    func note(id: UUID) -> NoteData? {
        let document = inboxDocuments.first { $0.entity.id == id }
            ?? archivedDocuments.first { $0.entity.id == id }
        return document?.noteData
    }

    func upsert(_ note: NoteData) {
        if let document = inboxDocuments.first(where: { $0.entity.id == note.id })
            ?? archivedDocuments.first(where: { $0.entity.id == note.id }) {
            document.entity = note.entity
            updateDocumentInArray(document)
        } else {
            let document = NoteDocument(fileURL: note.fileURL, entity: note.entity)
            if note.isArchived {
                archivedCachedUrls.append(note.fileURL)
                archivedDocuments.append(document)
            } else {
                inboxCachedUrls.append(note.fileURL)
                inboxDocuments.append(document)
            }
        }
    }

    // MARK: - Private helpers

    private func updateDocumentInArray(_ document: NoteDocument) {
        if let idx = inboxDocuments.firstIndex(where: { $0.entity.id == document.entity.id }) {
            inboxDocuments[idx] = document
        }
        if let idx = archivedDocuments.firstIndex(where: { $0.entity.id == document.entity.id }) {
            archivedDocuments[idx] = document
        }
    }

    private func removeDocumentFromArrays(_ document: NoteDocument) {
        inboxCachedUrls.removeAll { $0 == document.fileURL }
        archivedCachedUrls.removeAll { $0 == document.fileURL }
        inboxDocuments.removeAll { $0.entity.id == document.entity.id }
        archivedDocuments.removeAll { $0.entity.id == document.entity.id }
    }
}

enum NoteStoreError: LocalizedError {
    case openFailed(count: Int)
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .openFailed(let count):
            "Failed to load \(count) note(s). The files may be corrupted or not downloaded yet."
        case .saveFailed:
            "Failed to save the note."
        case .deleteFailed:
            "Failed to delete the note."
        }
    }
}
