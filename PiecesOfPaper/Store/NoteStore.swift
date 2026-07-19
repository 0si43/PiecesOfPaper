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
    private(set) var inboxNotes = [NoteData]()
    private(set) var archivedNotes = [NoteData]()

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
    var noteToShare: NoteData?
    var noteToTag: NoteData?

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
        noteRepository.setCloudUpdateHandler { [weak self] in
            guard let self else { return }
            Task { await self.applyCloudUpdate() }
        }
    }

    // MARK: - Computed display notes (replaces dual-management)

    var displayInboxNotes: [NoteData] {
        reorderNotes(inboxNotes, listOrder: inboxListOrder)
    }

    var displayArchivedNotes: [NoteData] {
        reorderNotes(archivedNotes, listOrder: archivedListOrder)
    }

    func displayNotes(for directory: NoteDirectory) -> [NoteData] {
        switch directory {
        case .inbox: displayInboxNotes
        case .archived: displayArchivedNotes
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

    func incrementalFetch(directory: NoteDirectory, background: Bool = false) async {
        defer { if !background { isLoading = false } }
        if !background { isLoading = true }
        let (added, removed) = await fetchChangedFileUrls(directory: directory)
        await updateNotes(addedUrls: added, removedUrls: removed, directory: directory, background: background)
    }

    /// Called when the iCloud metadata query reports remote changes,
    /// so the list follows sync progress without a manual reload.
    func applyCloudUpdate() async {
        await incrementalFetch(directory: .inbox, background: true)
        await incrementalFetch(directory: .archived, background: true)
    }

    func reload(directory: NoteDirectory) async {
        switch directory {
        case .inbox:
            inboxNotes.removeAll()
            inboxCachedUrls.removeAll()
        case .archived:
            archivedNotes.removeAll()
            archivedCachedUrls.removeAll()
        }
        await incrementalFetch(directory: directory)
    }

    private func fetchChangedFileUrls(directory: NoteDirectory) async -> (addedUrls: [URL], removedUrls: [URL]) {
        let latestUrls = await noteRepository.getFileUrls(directory: directory)
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

    private func updateNotes(addedUrls: [URL], removedUrls: [URL],
                             directory: NoteDirectory, background: Bool) async {
        let (newNotes, failedUrls) = await withTaskGroup(
            of: (url: URL, note: NoteData?).self
        ) { group -> ([NoteData], [URL]) in
            for url in addedUrls {
                group.addTask {
                    (url, try? await self.noteRepository.open(fileUrl: url))
                }
            }

            var notes: [NoteData] = []
            var failed: [URL] = []
            for await result in group {
                if let note = result.note {
                    notes.append(note)
                } else {
                    failed.append(result.url)
                }
            }

            return (notes, failed)
        }

        switch directory {
        case .inbox:
            // Filter re-appends: a cloud update and a user-initiated fetch can
            // overlap across the awaited opens and resolve the same added URL
            inboxNotes += newNotes.filter { note in !inboxNotes.contains { $0.id == note.id } }
            // Drop failed URLs from the cache so the next fetch retries them
            inboxCachedUrls.removeAll { failedUrls.contains($0) }
            removedUrls.forEach { url in
                inboxNotes.removeAll { $0.fileURL == url }
            }
        case .archived:
            archivedNotes += newNotes.filter { note in !archivedNotes.contains { $0.id == note.id } }
            archivedCachedUrls.removeAll { failedUrls.contains($0) }
            removedUrls.forEach { url in
                archivedNotes.removeAll { $0.fileURL == url }
            }
        }

        // Background updates retry failed files on the next query update,
        // so surfacing an alert for them would only interrupt the user.
        if !failedUrls.isEmpty && !background {
            alertType = .error(NoteStoreError.openFailed(count: failedUrls.count))
            showAlert = true
        }
    }

    // MARK: - Reorder helper

    private func reorderNotes(_ notes: [NoteData], listOrder: ListOrder) -> [NoteData] {
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

    func duplicate(_ note: NoteData, in directory: NoteDirectory) {
        noteRepository.duplicate(note, in: directory) { [weak self] newNote in
            guard let self else { return }
            guard let newNote else {
                self.alertType = .error(NoteStoreError.saveFailed)
                self.showAlert = true
                return
            }
            switch directory {
            case .inbox:
                self.inboxCachedUrls.append(newNote.fileURL)
                self.inboxNotes.append(newNote)
            case .archived:
                self.archivedCachedUrls.append(newNote.fileURL)
                self.archivedNotes.append(newNote)
            }
        }
    }

    func delete(_ note: NoteData) {
        do {
            try noteRepository.delete(fileUrl: note.fileURL)
            removeNoteFromArrays(note)
        } catch {
            alertType = .error(NoteStoreError.deleteFailed)
            showAlert = true
        }
    }

    func archive(_ note: NoteData) {
        do {
            let newUrl = try noteRepository.move(fileUrl: note.fileURL, to: .archived)
            inboxCachedUrls.removeAll { $0 == note.fileURL }
            inboxNotes.removeAll { $0.id == note.id }
            archivedCachedUrls.append(newUrl)
            archivedNotes.append(NoteData(entity: note.entity, fileURL: newUrl))
        } catch {
            print("Could not archive: ", error.localizedDescription)
        }
    }

    func unarchive(_ note: NoteData) {
        do {
            let newUrl = try noteRepository.move(fileUrl: note.fileURL, to: .inbox)
            archivedCachedUrls.removeAll { $0 == note.fileURL }
            archivedNotes.removeAll { $0.id == note.id }
            inboxCachedUrls.append(newUrl)
            inboxNotes.append(NoteData(entity: note.entity, fileURL: newUrl))
        } catch {
            print("Could not unarchive: ", error.localizedDescription)
        }
    }

    func allArchive() {
        let notes = inboxNotes
        notes.forEach { archive($0) }
    }

    func allUnarchive() {
        let notes = archivedNotes
        notes.forEach { unarchive($0) }
    }

    // MARK: - Tag operations on notes

    func addTag(_ tag: TagEntity, to note: NoteData) {
        guard let current = self.note(id: note.id) else { return }
        var updated = current
        updated.entity.tags.append(tag)
        replace(updated)
        noteRepository.save(updated.entity, to: updated.fileURL) { [weak self] success in
            guard let self else { return }
            if !success {
                self.replace(current)
                self.alertType = .error(NoteStoreError.saveFailed)
                self.showAlert = true
            }
        }
    }

    func removeTag(_ tag: TagEntity, from note: NoteData) {
        guard let current = self.note(id: note.id) else { return }
        var updated = current
        updated.entity.tags.removeAll { $0 == tag }
        replace(updated)
        noteRepository.save(updated.entity, to: updated.fileURL) { [weak self] success in
            guard let self else { return }
            if !success {
                self.replace(current)
                self.alertType = .error(NoteStoreError.saveFailed)
                self.showAlert = true
            }
        }
    }

    // MARK: - Note lookup & write-back

    func note(id: UUID) -> NoteData? {
        inboxNotes.first { $0.id == id } ?? archivedNotes.first { $0.id == id }
    }

    func upsert(_ note: NoteData) {
        if self.note(id: note.id) != nil {
            replace(note)
        } else if note.isArchived {
            archivedCachedUrls.append(note.fileURL)
            archivedNotes.append(note)
        } else {
            inboxCachedUrls.append(note.fileURL)
            inboxNotes.append(note)
        }
    }

    // MARK: - Canvas support

    var canRequestReview: Bool {
        inboxNotes.count >= 5
    }

    func save(drawing: PKDrawing, to note: NoteData, completion: @escaping (NoteData?) -> Void) {
        // Base on the store's copy, not the caller's snapshot: the caller may hold a
        // stale note while an earlier save is in flight
        let current = self.note(id: note.id) ?? note
        guard drawing != current.entity.drawing else {
            completion(current)
            return
        }
        var updated = current
        updated.entity.drawing = drawing
        updated.entity.updatedDate = Date()
        noteRepository.save(updated.entity, to: updated.fileURL) { [weak self] success in
            if success {
                self?.upsert(updated)
                completion(updated)
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - Private helpers

    private func replace(_ note: NoteData) {
        if let idx = inboxNotes.firstIndex(where: { $0.id == note.id }) {
            inboxNotes[idx] = note
        }
        if let idx = archivedNotes.firstIndex(where: { $0.id == note.id }) {
            archivedNotes[idx] = note
        }
    }

    private func removeNoteFromArrays(_ note: NoteData) {
        inboxCachedUrls.removeAll { $0 == note.fileURL }
        archivedCachedUrls.removeAll { $0 == note.fileURL }
        inboxNotes.removeAll { $0.id == note.id }
        archivedNotes.removeAll { $0.id == note.id }
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
