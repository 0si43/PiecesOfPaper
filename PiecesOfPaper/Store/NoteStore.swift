//
//  NoteStore.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

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
    var canvasDocument: NoteDocument?
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
        do {
            let newDocuments = try await withThrowingTaskGroup(of: NoteDocument.self) { [weak self] group in
                guard let self = self else { return [NoteDocument]() }
                var documents: [NoteDocument] = []
                for url in addedUrls {
                    group.addTask {
                        try await self.noteRepository.open(fileUrl: url)
                    }
                }

                for try await document in group {
                    documents.append(document)
                }

                return documents
            }

            switch directory {
            case .inbox:
                inboxDocuments += newDocuments
                removedUrls.forEach { url in
                    inboxDocuments.removeAll { $0.fileURL == url }
                }
            case .archived:
                archivedDocuments += newDocuments
                removedUrls.forEach { url in
                    archivedDocuments.removeAll { $0.fileURL == url }
                }
            }
        } catch {
            // FIXME: - need alert
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

    func save(document: NoteDocument) {
        document.entity.updatedDate = Date()
        noteRepository.save(document: document)
        updateDocumentInArray(document)
    }

    func save(document: NoteDocument, drawing: PKDrawing) {
        guard document.entity.drawing != drawing else { return }
        document.entity.drawing = drawing
        document.entity.updatedDate = Date()
        noteRepository.save(document: document)
        updateDocumentInArray(document)
    }

    func createNewNote() -> NoteDocument? {
        guard let inboxUrl = FilePath.inboxUrl else { return nil }
        let newUrl = inboxUrl.appendingPathComponent(FilePath.fileName)
        let entity = NoteEntity(drawing: PKDrawing())
        let newDocument = NoteDocument(fileURL: newUrl, entity: entity)
        noteRepository.save(document: newDocument, for: .forCreating)
        inboxCachedUrls.append(newUrl)
        inboxDocuments.append(newDocument)
        return newDocument
    }

    func duplicate(_ document: NoteDocument, in directory: NoteDirectory) {
        guard let newDocument = noteRepository.duplicate(document: document, in: directory) else { return }
        switch directory {
        case .inbox:
            inboxCachedUrls.append(newDocument.fileURL)
            inboxDocuments.append(newDocument)
        case .archived:
            archivedCachedUrls.append(newDocument.fileURL)
            archivedDocuments.append(newDocument)
        }
    }

    func delete(_ document: NoteDocument) {
        do {
            try noteRepository.delete(fileUrl: document.fileURL)
            removeDocumentFromArrays(document)
        } catch {
            // FIXME: - need alert
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
        noteRepository.save(document: document)
        updateDocumentInArray(document)
    }

    func removeTag(_ tag: TagEntity, from document: NoteDocument) {
        document.entity.tags.removeAll { $0 == tag }
        noteRepository.save(document: document)
        updateDocumentInArray(document)
    }

    // MARK: - Review request helper

    var canReviewRequest: Bool {
        guard let inboxUrl = FilePath.inboxUrl,
              let inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: inboxUrl.path) else {
            return false
        }
        return inboxFileNames.count >= 5
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
