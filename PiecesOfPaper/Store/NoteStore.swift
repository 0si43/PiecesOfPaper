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
    private(set) var inboxIndex = [NoteIndexEntry]()
    private(set) var archivedIndex = [NoteIndexEntry]()
    private(set) var metadataByUrl = [URL: NoteMetadata]()

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

    // Cell tasks, canvas taps, and filter hydration can request the same file
    // at once; one UIDocument open serves all of them.
    private var inFlightLoads: [URL: Task<NoteData?, Never>] = [:]

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

    // MARK: - Computed display entries

    var displayInboxEntries: [NoteIndexEntry] {
        reorderEntries(inboxIndex, listOrder: inboxListOrder)
    }

    var displayArchivedEntries: [NoteIndexEntry] {
        reorderEntries(archivedIndex, listOrder: archivedListOrder)
    }

    func displayEntries(for directory: NoteDirectory) -> [NoteIndexEntry] {
        switch directory {
        case .inbox: displayInboxEntries
        case .archived: displayArchivedEntries
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

    func fetch(directory: NoteDirectory, background: Bool = false) async {
        defer { if !background { isLoading = false } }
        if !background { isLoading = true }
        let entries = await noteRepository.getFileAttributes(directory: directory).map {
            NoteIndexEntry(fileURL: $0.fileURL,
                           creationDate: $0.creationDate,
                           contentModificationDate: $0.contentModificationDate)
        }
        // Wholesale assignment keeps overlapping fetches last-writer-wins; the
        // equality guard avoids re-rendering (and re-running cell load tasks)
        // when nothing changed.
        switch directory {
        case .inbox:
            if entries != inboxIndex { inboxIndex = entries }
        case .archived:
            if entries != archivedIndex { archivedIndex = entries }
        }
    }

    /// Called when the iCloud metadata query reports remote changes,
    /// so the list follows sync progress without a manual reload.
    func applyCloudUpdate() async {
        await fetch(directory: .inbox, background: true)
        await fetch(directory: .archived, background: true)
    }

    // MARK: - Lazy note loading

    /// Opens one document, records its listing metadata, and hands the loaded
    /// note to the caller to use and discard. The store never retains the drawing.
    func loadNote(_ entry: NoteIndexEntry) async -> NoteData? {
        if let inFlight = inFlightLoads[entry.fileURL] {
            return await inFlight.value
        }
        let load = Task { [noteRepository] in
            try? await noteRepository.open(fileUrl: entry.fileURL)
        }
        inFlightLoads[entry.fileURL] = load
        let note = await load.value
        inFlightLoads[entry.fileURL] = nil
        if let note {
            metadataByUrl[entry.fileURL] = NoteMetadata(id: note.entity.id,
                                                        tags: note.entity.tags,
                                                        updatedDate: entry.updatedDate)
        }
        return note
    }

    func validMetadata(for entry: NoteIndexEntry) -> NoteMetadata? {
        guard let metadata = metadataByUrl[entry.fileURL],
              metadata.updatedDate == entry.updatedDate else { return nil }
        return metadata
    }

    /// Tags for a list row; empty until the row's document has been opened.
    func tags(for entry: NoteIndexEntry) -> [TagEntity] {
        validMetadata(for: entry)?.tags ?? []
    }

    func requestShare(_ entry: NoteIndexEntry) {
        Task {
            if let note = await loadNote(entry) {
                noteToShare = note
            } else {
                presentOpenFailedAlert()
            }
        }
    }

    func requestTag(_ entry: NoteIndexEntry) {
        Task {
            if let note = await loadNote(entry) {
                noteToTag = note
            } else {
                presentOpenFailedAlert()
            }
        }
    }

    func presentOpenFailedAlert() {
        alertType = .error(NoteStoreError.openFailed(count: 1))
        showAlert = true
    }

    // MARK: - Reorder helper

    private func reorderEntries(_ entries: [NoteIndexEntry], listOrder: ListOrder) -> [NoteIndexEntry] {
        var filtered = entries
        if !listOrder.filterBy.isEmpty {
            // Tags live inside each document, so only notes with loaded
            // metadata can match while a filter is active.
            filtered = filtered.filter { entry in
                guard let metadata = validMetadata(for: entry) else { return false }
                return listOrder.filterBy.allSatisfy { metadata.tags.contains($0) }
            }
        }
        let ascending = listOrder.sortOrder == .ascending
        filtered.sort { lhs, rhs in
            let lhsDate = sortDate(of: lhs, by: listOrder.sortBy)
            let rhsDate = sortDate(of: rhs, by: listOrder.sortBy)
            guard lhsDate != rhsDate else {
                return ascending
                    ? lhs.fileURL.lastPathComponent < rhs.fileURL.lastPathComponent
                    : lhs.fileURL.lastPathComponent > rhs.fileURL.lastPathComponent
            }
            return ascending ? lhsDate < rhsDate : lhsDate > rhsDate
        }
        return filtered
    }

    private func sortDate(of entry: NoteIndexEntry, by sortBy: ListOrder.SortBy) -> Date {
        switch sortBy {
        case .updatedDate: entry.updatedDate
        case .createdDate: entry.createdDate
        }
    }
}

// MARK: - Data operations

extension NoteStore {
    func duplicate(_ entry: NoteIndexEntry, in directory: NoteDirectory) {
        Task {
            guard let note = await loadNote(entry) else {
                presentOpenFailedAlert()
                return
            }
            noteRepository.duplicate(note, in: directory) { [weak self] newNote in
                guard let self else { return }
                guard let newNote else {
                    self.alertType = .error(NoteStoreError.saveFailed)
                    self.showAlert = true
                    return
                }
                self.applySaved(newNote)
            }
        }
    }

    func delete(_ entry: NoteIndexEntry) {
        do {
            try noteRepository.delete(fileUrl: entry.fileURL)
            inboxIndex.removeAll { $0.fileURL == entry.fileURL }
            archivedIndex.removeAll { $0.fileURL == entry.fileURL }
            metadataByUrl[entry.fileURL] = nil
        } catch {
            alertType = .error(NoteStoreError.deleteFailed)
            showAlert = true
        }
    }

    func archive(_ entry: NoteIndexEntry) {
        moveEntry(entry, to: .archived)
    }

    func unarchive(_ entry: NoteIndexEntry) {
        moveEntry(entry, to: .inbox)
    }

    private func moveEntry(_ entry: NoteIndexEntry, to directory: NoteDirectory) {
        do {
            let newUrl = try noteRepository.move(fileUrl: entry.fileURL, to: directory)
            inboxIndex.removeAll { $0.fileURL == entry.fileURL }
            archivedIndex.removeAll { $0.fileURL == entry.fileURL }
            switch directory {
            case .inbox: upsertEntry(entry.moved(to: newUrl), into: &inboxIndex)
            case .archived: upsertEntry(entry.moved(to: newUrl), into: &archivedIndex)
            }
            rekeyMetadata(from: entry.fileURL, to: newUrl)
        } catch {
            print("Could not move note: ", error.localizedDescription)
        }
    }

    func allArchive() {
        let entries = inboxIndex
        entries.forEach { archive($0) }
    }

    func allUnarchive() {
        let entries = archivedIndex
        entries.forEach { unarchive($0) }
    }

    // MARK: - Tag operations

    func addTag(_ tag: TagEntity, to note: NoteData) {
        updateTags(of: note) { $0 + [tag] }
    }

    func removeTag(_ tag: TagEntity, from note: NoteData) {
        updateTags(of: note) { tags in tags.filter { $0 != tag } }
    }

    /// The caller's snapshot may predate tag edits made elsewhere; the
    /// metadata cache holds the latest known tags for the file.
    func currentTags(for note: NoteData) -> [TagEntity] {
        metadataByUrl[note.fileURL]?.tags ?? note.entity.tags
    }

    private func updateTags(of note: NoteData, _ transform: ([TagEntity]) -> [TagEntity]) {
        let previous = metadataByUrl[note.fileURL]
        var updated = note
        updated.entity.tags = transform(currentTags(for: note))
        // Optimistic cache update so the tag sheet and list rows reflect
        // the change before the save lands; rolled back on failure.
        metadataByUrl[note.fileURL] = NoteMetadata(
            id: previous?.id ?? note.entity.id,
            tags: updated.entity.tags,
            updatedDate: previous?.updatedDate ?? entry(for: note.fileURL)?.updatedDate ?? note.entity.updatedDate
        )
        noteRepository.save(updated.entity, to: updated.fileURL) { [weak self] success in
            guard let self else { return }
            if success {
                self.applySaved(updated)
            } else {
                self.metadataByUrl[note.fileURL] = previous
                self.alertType = .error(NoteStoreError.saveFailed)
                self.showAlert = true
            }
        }
    }

}

// MARK: - Canvas support & index write-back

extension NoteStore {
    var canRequestReview: Bool {
        inboxIndex.count >= 5
    }

    func save(drawing: PKDrawing, to note: NoteData, completion: @escaping (NoteData?) -> Void) {
        var payload = note
        // Tags edited from the list while the canvas held this snapshot live
        // in the metadata cache, not in the snapshot
        payload.entity.tags = currentTags(for: note)
        guard drawing != payload.entity.drawing else {
            completion(payload)
            return
        }
        payload.entity.drawing = drawing
        payload.entity.updatedDate = Date()
        noteRepository.save(payload.entity, to: payload.fileURL) { [weak self] success in
            if success {
                self?.applySaved(payload)
                completion(payload)
            } else {
                completion(nil)
            }
        }
    }

    /// Refreshes the index entry and metadata for a note just written to disk.
    /// Dates are read back from the file so the entry matches what the next
    /// enumeration reports; a mismatch would invalidate the thumbnail and
    /// force one extra document open per saved note.
    func applySaved(_ note: NoteData) {
        let attributes = noteRepository.fileAttributes(at: note.fileURL)
        let entry = NoteIndexEntry(fileURL: note.fileURL,
                                   creationDate: attributes?.creationDate ?? note.entity.createdDate,
                                   contentModificationDate: attributes?.contentModificationDate ?? note.entity.updatedDate)
        metadataByUrl[note.fileURL] = NoteMetadata(id: note.entity.id,
                                                   tags: note.entity.tags,
                                                   updatedDate: entry.updatedDate)
        if note.isArchived {
            upsertEntry(entry, into: &archivedIndex)
        } else {
            upsertEntry(entry, into: &inboxIndex)
        }
    }

    // MARK: - Private helpers

    private func upsertEntry(_ entry: NoteIndexEntry, into index: inout [NoteIndexEntry]) {
        if let existing = index.firstIndex(where: { $0.fileURL == entry.fileURL }) {
            index[existing] = entry
        } else {
            index.append(entry)
        }
    }

    private func rekeyMetadata(from oldUrl: URL, to newUrl: URL) {
        guard oldUrl != newUrl else { return }
        metadataByUrl[newUrl] = metadataByUrl.removeValue(forKey: oldUrl)
    }

    private func entry(for fileUrl: URL) -> NoteIndexEntry? {
        inboxIndex.first { $0.fileURL == fileUrl } ?? archivedIndex.first { $0.fileURL == fileUrl }
    }
}
