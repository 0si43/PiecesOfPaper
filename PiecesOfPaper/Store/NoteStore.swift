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
    /// External opens can fail while no note list is mounted, so this one is
    /// presented by RootSplitView rather than by a list screen
    var showExternalOpenAlert = false
    private(set) var externalOpenError: Error?
    /// Set on the cloud→local transition while the iCloud preference is still
    /// on, so the list screen can explain why the visible notes changed
    private(set) var didFallBackToLocalStorage = false
    private var lastFetchUsedCloudStorage: Bool?
    @ObservationIgnored private var hasBecomeActive = false
    @ObservationIgnored private var lastEnteredBackground: Date?

    // MARK: - Dependencies
    // Read here and by NoteStore+DataOperations
    let noteRepository: NoteRepositoryProtocol
    private let preferenceRepository: PreferenceRepositoryProtocol
    let metadataCacheRepository: NoteMetadataCacheRepositoryProtocol
    /// Receives tags embedded in a legacy note; wired by RootSplitView so the
    /// store stays independent of TagStore.
    @ObservationIgnored var onLegacyTagsDecoded: (([TagEntity]) -> Void)?

    // Cell tasks, canvas taps, and filter hydration can request the same file
    // at once; one UIDocument open serves all of them.
    private var inFlightLoads: [URL: Task<Result<NoteData, Error>, Never>] = [:]

    // Pull-to-refresh, the Reload button, and cloud updates can request the
    // same directory at once; one enumeration serves all of them.
    private var inFlightFetches: [NoteDirectory: Task<Void, Never>] = [:]

    // Coordinated deletes and moves take an unbounded amount of time, so the
    // index is updated optimistically. The pending set hides files whose
    // operation has not landed yet from enumeration results, preventing a
    // concurrent fetch from resurrecting a note mid-operation.
    // Written by NoteStore+DataOperations, read here.
    var pendingFileOperationUrls: Set<URL> = []

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
        if let inFlight = inFlightFetches[directory] {
            await inFlight.value
            return
        }
        let fetchTask = Task { await performFetch(directory: directory) }
        inFlightFetches[directory] = fetchTask
        await fetchTask.value
        inFlightFetches[directory] = nil
    }

    private func performFetch(directory: NoteDirectory) async {
        trackStorageModeTransition()
        let entries = await noteRepository.getFileAttributes(directory: directory)
            .filter { !pendingFileOperationUrls.contains($0.fileURL) }
            .map {
                NoteIndexEntry(fileURL: $0.fileURL,
                               creationDate: $0.creationDate,
                               contentModificationDate: $0.contentModificationDate)
            }
        // The equality guard avoids re-rendering (and re-running cell load
        // tasks) when nothing changed.
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

    // Snapshotted once per fetch so a flip cannot land between the mode check
    // and the enumeration. The preference guard keeps the user-initiated
    // "Use device storage" path (toggle off, then refetch) warn-free.
    private func trackStorageModeTransition() {
        let usingCloud = noteRepository.isCloudStorageActive
        if lastFetchUsedCloudStorage == true, !usingCloud, preferenceRepository.getEnablediCloud() {
            didFallBackToLocalStorage = true
        }
        lastFetchUsedCloudStorage = usingCloud
    }

    func acknowledgeLocalStorageFallback() {
        didFallBackToLocalStorage = false
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
        try? await loadNoteResult(entry).get()
    }

    /// Like `loadNote`, for callers that surface why the open failed
    /// (corrupt file vs. undownloaded iCloud item).
    func loadNoteResult(_ entry: NoteIndexEntry) async -> Result<NoteData, Error> {
        if let inFlight = inFlightLoads[entry.fileURL] {
            return await inFlight.value
        }
        let load = Task { [noteRepository] in
            do {
                return Result<NoteData, Error>.success(try await noteRepository.open(fileUrl: entry.fileURL))
            } catch {
                return Result<NoteData, Error>.failure(error)
            }
        }
        inFlightLoads[entry.fileURL] = load
        let result = await load.value
        inFlightLoads[entry.fileURL] = nil
        // A delete or move started while this open was in flight already dropped
        // the entry; recording metadata here would resurrect the dead file name.
        if case .success(let note) = result, !pendingFileOperationUrls.contains(entry.fileURL) {
            metadataByFileName[entry.fileName] = NoteMetadata(id: note.entity.id,
                                                              tagIds: note.entity.tagIds,
                                                              updatedDate: entry.updatedDate)
            salvageLegacyTags(of: note)
            schedulePersist()
        }
        return result
    }

    func validMetadata(for entry: NoteIndexEntry) -> NoteMetadata? {
        guard let metadata = metadataByFileName[entry.fileName],
              metadata.updatedDate == entry.updatedDate else { return nil }
        return metadata
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

    /// Not cold-launch-only: iOS keeps the process alive for days, so "open the
    /// app next morning" is usually a foreground resume. The threshold keeps
    /// the open-and-write experience for those while short app switches resume
    /// quietly.
    static let autoOpenBackgroundThreshold: TimeInterval = 30 * 60

    func sceneDidEnterBackground(now: Date = .now) {
        lastEnteredBackground = now
    }

    /// Auto-opens a blank note on cold launch or after a long background stay.
    /// Brief interruptions (.inactive bounces, short app switches) never
    /// re-trigger it
    func sceneDidBecomeActive(now: Date = .now) {
        let isColdLaunch = !hasBecomeActive
        hasBecomeActive = true
        let resumedAfterLongBackground = lastEnteredBackground
            .map { now.timeIntervalSince($0) >= Self.autoOpenBackgroundThreshold } ?? false
        lastEnteredBackground = nil
        guard isColdLaunch || resumedAfterLongBackground else { return }
        openBlankNoteIfIdle()
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
            salvageLegacyTags(of: note)
        } catch {
            scopedUrl?.stopAccessingSecurityScopedResource()
            guard !Task.isCancelled else { return }
            externalOpenError = error
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

// MARK: - Canvas support

extension NoteStore {
    var canRequestReview: Bool {
        inboxIndex.count >= 5
    }

    func save(drawing: PKDrawing, to note: NoteData) async throws -> NoteData {
        var payload = note
        // Tags edited from the list while the canvas held this snapshot live
        // in the metadata cache, not in the snapshot
        payload.entity.tagIds = currentTagIds(for: note)
        guard drawing != payload.entity.drawing else {
            return payload
        }
        payload.entity.drawing = drawing
        payload.entity.updatedDate = Date()
        try await noteRepository.save(payload.entity, to: payload.fileURL)
        applySaved(payload)
        return payload
    }
}

// MARK: - Index mutation

// The only way to write the two indexes: their setters stay private, so
// NoteStore+DataOperations goes through these instead of taking them inout.
extension NoteStore {
    func upsertEntry(_ entry: NoteIndexEntry, in directory: NoteDirectory) {
        switch directory {
        case .inbox: upsert(entry, into: &inboxIndex)
        case .archived: upsert(entry, into: &archivedIndex)
        }
    }

    func removeEntryFromIndexes(_ fileUrl: URL) {
        inboxIndex.removeAll { $0.fileURL == fileUrl }
        archivedIndex.removeAll { $0.fileURL == fileUrl }
    }

    private func upsert(_ entry: NoteIndexEntry, into index: inout [NoteIndexEntry]) {
        if let existing = index.firstIndex(where: { $0.fileURL == entry.fileURL }) {
            index[existing] = entry
        } else {
            index.append(entry)
        }
    }
}
