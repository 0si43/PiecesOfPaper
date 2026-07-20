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
    /// Single source of truth for canvas presentation: new notes, thumbnail
    /// taps, and external opens all present by assigning this
    var openedNote: NoteData?
    private(set) var isHandlingExternalOpen = false
    private(set) var externalOpenTask: Task<Void, Never>?
    private var securityScopedUrl: URL?
    /// Separate from showAlert: external opens can fail while NoteListParentView
    /// (the showAlert host) is unmounted, so SideBarListView presents this one
    var showExternalOpenAlert = false
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

    // Coordinated deletes and moves take an unbounded amount of time, so the
    // index is updated optimistically and these two keep it consistent:
    // the task chain runs one operation at a time, and the pending set hides
    // files whose operation has not landed yet from enumeration results.
    private var fileOperationTask: Task<Void, Never>?
    private var pendingFileOperationUrls: Set<URL> = []

    // Tag-filter hydration state, driven by NoteStore+Loading
    var hydrationTasks: [NoteDirectory: Task<Void, Never>] = [:]
    var hydratingDirectories: Set<NoteDirectory> = []

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
        ensureMetadataForFilter(directory: directory)
    }

    // MARK: - Fetch

    func fetch(directory: NoteDirectory, background: Bool = false) async {
        defer { if !background { isLoading = false } }
        if !background { isLoading = true }
        let entries = await noteRepository.getFileAttributes(directory: directory)
            .filter { !pendingFileOperationUrls.contains($0.fileURL) }
            .map {
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
        if !listOrder(for: directory).filterBy.isEmpty {
            ensureMetadataForFilter(directory: directory)
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
        // A delete or move started while this open was in flight already dropped
        // the entry; recording metadata here would resurrect the dead URL.
        if let note, !pendingFileOperationUrls.contains(entry.fileURL) {
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
        enqueueFileOperation { await self.performDelete(entry) }
    }

    func archive(_ entry: NoteIndexEntry) {
        enqueueFileOperation { await self.performMove(entry, to: .archived) }
    }

    func unarchive(_ entry: NoteIndexEntry) {
        enqueueFileOperation { await self.performMove(entry, to: .inbox) }
    }

    func allArchive() {
        let entries = inboxIndex
        enqueueFileOperation {
            for entry in entries {
                await self.performMove(entry, to: .archived)
            }
        }
    }

    func allUnarchive() {
        let entries = archivedIndex
        enqueueFileOperation {
            for entry in entries {
                await self.performMove(entry, to: .inbox)
            }
        }
    }

    private func performDelete(_ entry: NoteIndexEntry) async {
        // Gone from the index means the operation already ran, so a repeated
        // tap queued behind the first one does nothing.
        guard let sourceDirectory = directory(of: entry.fileURL) else { return }
        let metadata = metadataByUrl[entry.fileURL]
        pendingFileOperationUrls.insert(entry.fileURL)
        removeEntryFromIndexes(entry.fileURL)
        metadataByUrl[entry.fileURL] = nil
        do {
            try await noteRepository.delete(fileUrl: entry.fileURL)
        } catch {
            restoreEntry(entry, to: sourceDirectory, metadata: metadata)
            alertType = .error(NoteStoreError.deleteFailed)
            showAlert = true
        }
        pendingFileOperationUrls.remove(entry.fileURL)
    }

    private func performMove(_ entry: NoteIndexEntry, to directory: NoteDirectory) async {
        guard let sourceDirectory = self.directory(of: entry.fileURL) else { return }
        let metadata = metadataByUrl[entry.fileURL]
        pendingFileOperationUrls.insert(entry.fileURL)
        removeEntryFromIndexes(entry.fileURL)
        do {
            let newUrl = try await noteRepository.move(fileUrl: entry.fileURL, to: directory)
            switch directory {
            case .inbox: upsertEntry(entry.moved(to: newUrl), into: &inboxIndex)
            case .archived: upsertEntry(entry.moved(to: newUrl), into: &archivedIndex)
            }
            rekeyMetadata(from: entry.fileURL, to: newUrl)
        } catch {
            restoreEntry(entry, to: sourceDirectory, metadata: metadata)
            alertType = .error(NoteStoreError.moveFailed)
            showAlert = true
        }
        pendingFileOperationUrls.remove(entry.fileURL)
    }

    /// Serializes file operations: "Move all to Trash" queues one move per note,
    /// and overlapping operations would otherwise interleave their index updates.
    private func enqueueFileOperation(_ operation: @escaping () async -> Void) {
        let previous = fileOperationTask
        fileOperationTask = Task {
            await previous?.value
            await operation()
        }
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

// MARK: - Canvas presentation & external open

extension NoteStore {
    func openNewNote() {
        guard let url = FilePath.inboxUrl?.appendingPathComponent(FilePath.fileName) else { return }
        openedNote = NoteData(entity: NoteEntity(drawing: PKDrawing()), fileURL: url)
    }

    /// scenePhase .active hook: never stomp an already-open note or an
    /// in-flight external open
    func openBlankNoteIfIdle() {
        guard openedNote == nil, !isHandlingExternalOpen else { return }
        openNewNote()
    }

    /// Synchronous onOpenURL entry point. Sets the suppression flag before any
    /// await so a later-arriving scenePhase .active cannot race in a blank canvas
    func handleIncomingURL(_ url: URL) {
        guard url.pathExtension == FilePath.noteFileExtension else { return }
        externalOpenTask?.cancel()
        isHandlingExternalOpen = true
        externalOpenTask = Task { await openExternalNote(url: url) }
    }

    func openExternalNote(url: URL) async {
        // A cancelled task no longer owns the flag — the newer external open does
        defer { if !Task.isCancelled { isHandlingExternalOpen = false } }
        guard openedNote?.fileURL != url else { return }
        let noteBeforeOpen = openedNote
        // false means the URL is not security-scoped (the app's own container),
        // so reading can proceed without holding a scope
        let scopedUrl: URL? = url.startAccessingSecurityScopedResource() ? url : nil
        do {
            let note = try await noteRepository.open(fileUrl: url)
            // Discard a superseded result: a newer external open cancelled this
            // task, or the user opened another note while the open was awaiting
            // a potentially long iCloud download
            guard !Task.isCancelled, openedNote?.id == noteBeforeOpen?.id else {
                scopedUrl?.stopAccessingSecurityScopedResource()
                return
            }
            // Swap scopes only after a successful open: releasing earlier would
            // break autosave of the still-presented previous note on failure
            releaseSecurityScope()
            securityScopedUrl = scopedUrl
            openedNote = note
        } catch {
            scopedUrl?.stopAccessingSecurityScopedResource()
            guard !Task.isCancelled else { return }
            showExternalOpenAlert = true
        }
    }

    /// Held while the note is open (autosave writes back to the scoped URL) and
    /// released only when the next external open succeeds. Dismissal keeps it:
    /// releasing there would race the final in-flight autosave, whose sandboxed
    /// write the revoked scope would deny
    private func releaseSecurityScope() {
        securityScopedUrl?.stopAccessingSecurityScopedResource()
        securityScopedUrl = nil
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
        } else if note.isInInbox {
            upsertEntry(entry, into: &inboxIndex)
        }
        // Notes outside both directories (opened in place from the Files app)
        // are edited at their own URL and never listed
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

    private func directory(of fileUrl: URL) -> NoteDirectory? {
        if inboxIndex.contains(where: { $0.fileURL == fileUrl }) { return .inbox }
        if archivedIndex.contains(where: { $0.fileURL == fileUrl }) { return .archived }
        return nil
    }

    private func removeEntryFromIndexes(_ fileUrl: URL) {
        inboxIndex.removeAll { $0.fileURL == fileUrl }
        archivedIndex.removeAll { $0.fileURL == fileUrl }
    }

    private func restoreEntry(_ entry: NoteIndexEntry, to directory: NoteDirectory, metadata: NoteMetadata?) {
        switch directory {
        case .inbox: upsertEntry(entry, into: &inboxIndex)
        case .archived: upsertEntry(entry, into: &archivedIndex)
        }
        metadataByUrl[entry.fileURL] = metadata
    }
}
