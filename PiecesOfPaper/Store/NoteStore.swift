import Foundation
import PencilKit

@Observable
@MainActor
final class NoteStore {
    // MARK: - Primary data (Single Source of Truth)
    private(set) var inboxIndex = [NoteIndexEntry]()
    private(set) var archivedIndex = [NoteIndexEntry]()
    // Written here and by NoteStore+MetadataCache
    var metadataByFileName = [String: NoteMetadata]()

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
    let metadataCacheRepository: NoteMetadataCacheRepositoryProtocol

    // Cell tasks, canvas taps, and filter hydration can request the same file
    // at once; one UIDocument open serves all of them.
    private var inFlightLoads: [URL: Task<NoteData?, Never>] = [:]

    // Tag-filter hydration state, driven by NoteStore+Loading
    var hydrationTasks: [NoteDirectory: Task<Void, Never>] = [:]
    var hydratingDirectories: Set<NoteDirectory> = []

    /// Awaited before tag-filter hydration so a cold start filters from the
    /// persisted cache instead of re-opening every note.
    private(set) var loadPersistedMetadataTask: Task<Void, Never>?
    var persistTask: Task<Void, Never>?

    init(noteRepository: NoteRepositoryProtocol = NoteRepository(),
         preferenceRepository: PreferenceRepositoryProtocol = PreferenceRepository(),
         metadataCacheRepository: NoteMetadataCacheRepositoryProtocol = NoteMetadataCacheRepository()) {
        self.noteRepository = noteRepository
        self.preferenceRepository = preferenceRepository
        self.metadataCacheRepository = metadataCacheRepository
        self.inboxListOrder = preferenceRepository.getListOrder(directoryName: NoteDirectory.inbox.rawValue)
        self.archivedListOrder = preferenceRepository.getListOrder(directoryName: NoteDirectory.archived.rawValue)
        noteRepository.setCloudUpdateHandler { [weak self] in
            guard let self else { return }
            Task { await self.applyCloudUpdate() }
        }
        loadPersistedMetadataTask = makePersistedMetadataLoad()
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
        if let note {
            metadataByFileName[entry.fileName] = NoteMetadata(id: note.entity.id,
                                                              tags: note.entity.tags,
                                                              updatedDate: entry.updatedDate)
            schedulePersist()
        }
        return note
    }

    func validMetadata(for entry: NoteIndexEntry) -> NoteMetadata? {
        guard let metadata = metadataByFileName[entry.fileName],
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
        do {
            try noteRepository.delete(fileUrl: entry.fileURL)
            inboxIndex.removeAll { $0.fileURL == entry.fileURL }
            archivedIndex.removeAll { $0.fileURL == entry.fileURL }
            metadataByFileName[entry.fileName] = nil
            schedulePersist()
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
            // The metadata cache is keyed by file name, which a move preserves,
            // so the moved note keeps its tags without a re-open
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
        metadataByFileName[note.fileName]?.tags ?? note.entity.tags
    }

    private func updateTags(of note: NoteData, _ transform: ([TagEntity]) -> [TagEntity]) {
        let previous = metadataByFileName[note.fileName]
        var updated = note
        updated.entity.tags = transform(currentTags(for: note))
        // Optimistic cache update so the tag sheet and list rows reflect
        // the change before the save lands; rolled back on failure.
        metadataByFileName[note.fileName] = NoteMetadata(
            id: previous?.id ?? note.entity.id,
            tags: updated.entity.tags,
            updatedDate: previous?.updatedDate ?? entry(for: note.fileURL)?.updatedDate ?? note.entity.updatedDate
        )
        schedulePersist()
        noteRepository.save(updated.entity, to: updated.fileURL) { [weak self] success in
            guard let self else { return }
            if success {
                self.applySaved(updated)
            } else {
                self.metadataByFileName[note.fileName] = previous
                self.schedulePersist()
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
        metadataByFileName[note.fileName] = NoteMetadata(id: note.entity.id,
                                                         tags: note.entity.tags,
                                                         updatedDate: entry.updatedDate)
        schedulePersist()
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

    private func entry(for fileUrl: URL) -> NoteIndexEntry? {
        inboxIndex.first { $0.fileURL == fileUrl } ?? archivedIndex.first { $0.fileURL == fileUrl }
    }
}
