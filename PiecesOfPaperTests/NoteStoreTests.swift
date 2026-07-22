import UIKit
import Testing
import PencilKit
@testable import Pieces_of_Paper

@MainActor
struct NoteStoreTests {
    var noteStore: NoteStore
    let repositoryMock: NoteRepositoryMock
    let preferenceRepositoryMock: PreferenceRepositoryMock
    let notes = NoteRepositoryMock.TestFile.allCases.map { NoteData.createTestData(fileURL: $0.url) }

    init() {
        repositoryMock = NoteRepositoryMock(notes: notes)
        preferenceRepositoryMock = PreferenceRepositoryMock()
        noteStore = NoteStore(
            noteRepository: repositoryMock,
            preferenceRepository: preferenceRepositoryMock,
            metadataCacheRepository: NoteMetadataCacheRepositoryMock()
        )
    }

    /// Delete and move run on the store's internal task chain, so assertions
    /// have to let it drain first.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<100 where !condition() {
            await Task.yield()
        }
    }

    // MARK: - Index fetch & sorting

    @Test func test_fetch_buildsIndexWithoutOpeningDocuments() async {
        await noteStore.fetch(directory: .inbox)
        #expect(noteStore.inboxIndex.map(\.fileURL) == NoteRepositoryMock.TestFile.allCases.map(\.url))
        #expect(repositoryMock.openCallCount == 0)
        #expect(!noteStore.isLoading)
    }

    @Test func test_fetch_dropsEntriesRemovedFromEnumeration() async {
        await noteStore.fetch(directory: .inbox)
        repositoryMock.enumeratedAttributes = [NoteRepositoryMock.TestFile.file1.attributes]
        await noteStore.fetch(directory: .inbox)
        #expect(noteStore.inboxIndex.map(\.fileURL) == [NoteRepositoryMock.TestFile.file1.url])
    }

    // file1 has the oldest filename timestamp (created) but the newest
    // modification date (updated), so the two sort keys produce opposite orders
    @Test func test_displayEntries_sortsBothKeysAndOrdersOnIndexAlone() async {
        await noteStore.fetch(directory: .inbox)
        let file1 = NoteRepositoryMock.TestFile.file1.url
        let file2 = NoteRepositoryMock.TestFile.file2.url
        let file3 = NoteRepositoryMock.TestFile.file3.url

        #expect(noteStore.displayInboxEntries.map(\.fileURL) == [file1, file2, file3])

        var order = ListOrder()
        order.sortBy = .updatedDate
        order.sortOrder = .ascending
        noteStore.inboxListOrder = order
        #expect(noteStore.displayInboxEntries.map(\.fileURL) == [file3, file2, file1])

        order.sortBy = .createdDate
        order.sortOrder = .descending
        noteStore.inboxListOrder = order
        #expect(noteStore.displayInboxEntries.map(\.fileURL) == [file3, file2, file1])

        order.sortOrder = .ascending
        noteStore.inboxListOrder = order
        #expect(noteStore.displayInboxEntries.map(\.fileURL) == [file1, file2, file3])

        #expect(repositoryMock.openCallCount == 0)
    }

    @Test func test_displayEntries_tagFilterShowsOnlyLoadedMatchingNotes() async throws {
        await noteStore.fetch(directory: .inbox)
        let tag = TagEntity(name: "work", color: CodableUIColor(uiColor: .blue))
        var order = ListOrder()
        order.filterBy = [tag]
        noteStore.inboxListOrder = order
        #expect(noteStore.displayInboxEntries.isEmpty)

        noteStore.addTag(tag, to: notes[0])
        #expect(noteStore.displayInboxEntries.map(\.fileURL) == [notes[0].fileURL])
    }

    // MARK: - Lazy note loading

    @Test func test_loadNote_cachesMetadataAndRetriesAfterFailure() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        repositoryMock.failingUrls = [entry.fileURL]

        let failed = await noteStore.loadNote(entry)
        #expect(failed == nil)
        #expect(!noteStore.showAlert)
        #expect(noteStore.metadataByFileName[entry.fileName] == nil)

        repositoryMock.failingUrls = []
        let loaded = await noteStore.loadNote(entry)
        #expect(loaded != nil)
        #expect(noteStore.metadataByFileName[entry.fileName]?.id == loaded?.entity.id)
        #expect(repositoryMock.openCallCount == 2)
    }

    @Test func test_loadNote_dedupesOverlappingOpens() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        async let first = noteStore.loadNote(entry)
        async let second = noteStore.loadNote(entry)
        let results = await [first, second]
        #expect(results.compactMap { $0 }.count == 2)
        #expect(repositoryMock.openCallCount == 1)
    }

    @Test func test_requestTag_opensNoteAndPresentsSheet() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        noteStore.requestTag(entry)
        for _ in 0..<100 where noteStore.noteToTag == nil {
            await Task.yield()
        }
        #expect(noteStore.noteToTag?.fileURL == entry.fileURL)
    }

    @Test func test_requestShare_alertsWhenOpenFails() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        repositoryMock.failingUrls = [entry.fileURL]
        noteStore.requestShare(entry)
        for _ in 0..<100 where !noteStore.showAlert {
            await Task.yield()
        }
        #expect(noteStore.showAlert)
        #expect(noteStore.noteToShare == nil)
    }

    // MARK: - Data operations

    @Test func test_duplicate_appendsEntryForTheNewFile() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        noteStore.duplicate(entry, in: .inbox)
        for _ in 0..<100 where noteStore.inboxIndex.count < 4 {
            await Task.yield()
        }
        #expect(noteStore.inboxIndex.count == 4)
        let newEntry = try #require(
            noteStore.inboxIndex.first { $0.fileURL.lastPathComponent.hasPrefix("duplicated-") }
        )
        #expect(noteStore.metadataByFileName[newEntry.fileName] != nil)
    }

    @Test func test_delete_removesEntryAndMetadata() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        _ = await noteStore.loadNote(entry)
        noteStore.delete(entry)
        await waitUntil { repositoryMock.deletedUrls.contains(entry.fileURL) }
        #expect(noteStore.inboxIndex.count == 2)
        #expect(noteStore.metadataByFileName[entry.fileName] == nil)
    }

    @Test func test_delete_restoresEntryAndAlertsWhenDeleteFails() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        repositoryMock.deleteShouldThrow = true

        noteStore.delete(entry)
        await waitUntil { noteStore.showAlert }

        #expect(noteStore.inboxIndex.count == 3)
        #expect(noteStore.inboxIndex.contains { $0.fileURL == entry.fileURL })
    }

    @Test func test_delete_ignoresARepeatedTapForTheSameEntry() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)

        noteStore.delete(entry)
        noteStore.delete(entry)
        await waitUntil { !repositoryMock.deletedUrls.isEmpty }
        // Give the queued second delete every chance to run before counting
        for _ in 0..<50 { await Task.yield() }

        #expect(repositoryMock.deletedUrls == [entry.fileURL])
        #expect(noteStore.inboxIndex.count == 2)
    }

    @Test func test_fetch_doesNotResurrectAnEntryWhileItsDeleteIsInFlight() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        repositoryMock.suspendFileOperations = true

        noteStore.delete(entry)
        await waitUntil { repositoryMock.hasPendingFileOperation }
        // Enumeration still reports the file: the removal has not landed yet
        await noteStore.fetch(directory: .inbox)

        #expect(!noteStore.inboxIndex.contains { $0.fileURL == entry.fileURL })

        repositoryMock.resumePendingFileOperations()
        await waitUntil { repositoryMock.deletedUrls.contains(entry.fileURL) }
        #expect(noteStore.inboxIndex.count == 2)
    }

    @Test func test_archive_movesEntryAndKeepsMetadataWithoutReopening() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        _ = await noteStore.loadNote(entry)

        noteStore.archive(entry)
        await waitUntil { !noteStore.archivedIndex.isEmpty }

        #expect(noteStore.inboxIndex.count == 2)
        let moved = try #require(noteStore.archivedIndex.first)
        #expect(moved.fileURL.lastPathComponent == entry.fileURL.lastPathComponent)
        #expect(moved.updatedDate == entry.updatedDate)
        #expect(noteStore.metadataByFileName[moved.fileName] != nil)
        #expect(repositoryMock.openCallCount == 1)
    }

    @Test func test_archive_keepsEntryWhenMoveFails() async {
        await noteStore.fetch(directory: .inbox)
        repositoryMock.moveShouldThrow = true
        let target = noteStore.displayInboxEntries[0]
        noteStore.archive(target)
        await waitUntil { noteStore.showAlert }
        #expect(noteStore.displayInboxEntries.count == 3)
        #expect(noteStore.displayArchivedEntries.isEmpty)
    }

    @Test func test_allArchive_movesEveryEntryInOrder() async {
        await noteStore.fetch(directory: .inbox)
        let urls = noteStore.inboxIndex.map(\.fileURL)

        noteStore.allArchive()
        await waitUntil { repositoryMock.movedUrls.count == urls.count }

        #expect(repositoryMock.movedUrls == urls)
        #expect(noteStore.inboxIndex.isEmpty)
        #expect(noteStore.archivedIndex.count == urls.count)
    }

    // MARK: - Tag operations

    @Test func test_addTag_updatesMetadataOnSuccessfulSave() async {
        await noteStore.fetch(directory: .inbox)
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        noteStore.addTag(tag, to: notes[0])
        #expect(noteStore.currentTagIds(for: notes[0]) == [tag.id])
        #expect(!noteStore.showAlert)
    }

    @Test func test_addTag_rollsBackTagWhenSaveFails() async {
        await noteStore.fetch(directory: .inbox)
        repositoryMock.saveShouldSucceed = false
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        noteStore.addTag(tag, to: notes[0])
        #expect(noteStore.currentTagIds(for: notes[0]).isEmpty)
        #expect(noteStore.showAlert)
    }

    // MARK: - List order settings

    @Test func test_inboxListOrder_persistsOnChange() {
        var order = ListOrder()
        order.sortBy = .createdDate
        order.sortOrder = .ascending
        noteStore.inboxListOrder = order
        #expect(preferenceRepositoryMock.setListOrderCalls.count == 1)
        let call = preferenceRepositoryMock.setListOrderCalls.first
        #expect(call?.directoryName == NoteDirectory.inbox.rawValue)
        #expect(call?.listOrder.sortBy == .createdDate)
        #expect(call?.listOrder.sortOrder == .ascending)
    }

    @Test func test_archivedListOrder_persistsOnChange() {
        var order = ListOrder()
        order.sortOrder = .ascending
        noteStore.archivedListOrder = order
        #expect(preferenceRepositoryMock.setListOrderCalls.count == 1)
        let call = preferenceRepositoryMock.setListOrderCalls.first
        #expect(call?.directoryName == NoteDirectory.archived.rawValue)
        #expect(call?.listOrder.sortOrder == .ascending)
    }

    @Test func test_init_restoresListOrdersWithoutRePersisting() {
        let preferenceMock = PreferenceRepositoryMock()
        var inboxOrder = ListOrder()
        inboxOrder.sortBy = .createdDate
        var archivedOrder = ListOrder()
        archivedOrder.sortOrder = .ascending
        preferenceMock.listOrders = [
            NoteDirectory.inbox.rawValue: inboxOrder,
            NoteDirectory.archived.rawValue: archivedOrder
        ]

        let store = NoteStore(
            noteRepository: NoteRepositoryMock(notes: []),
            preferenceRepository: preferenceMock,
            metadataCacheRepository: NoteMetadataCacheRepositoryMock()
        )
        #expect(store.inboxListOrder.sortBy == .createdDate)
        #expect(store.archivedListOrder.sortOrder == .ascending)
        #expect(preferenceMock.setListOrderCalls.isEmpty)
    }

    // MARK: - Index write-back

    @Test func test_applySaved_insertsEntryAndMetadata() {
        let note = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
        noteStore.applySaved(note)
        #expect(noteStore.inboxIndex.map(\.fileURL) == [note.fileURL])
        #expect(noteStore.metadataByFileName[note.fileName]?.id == note.entity.id)
    }

    @Test func test_applySaved_insertsArchivedNoteIntoArchivedIndex() throws {
        let archivedUrl = try #require(FilePath.archivedUrl).appendingPathComponent("2024-05-06-07-08-090000.pop")
        let note = NoteData.createTestData(fileURL: archivedUrl)
        noteStore.applySaved(note)
        #expect(noteStore.archivedIndex.map(\.fileURL) == [archivedUrl])
        #expect(noteStore.inboxIndex.isEmpty)
    }

    @Test func test_applySaved_ignoresFileOutsideManagedDirectories() {
        let note = NoteData.createTestData(fileURL: URL(fileURLWithPath: "/external/note.pop"))
        noteStore.applySaved(note)
        #expect(noteStore.inboxIndex.isEmpty)
        #expect(noteStore.archivedIndex.isEmpty)
    }

    @Test func test_applySaved_thenFetchDoesNotDuplicate() async {
        noteStore.applySaved(NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url))
        await noteStore.fetch(directory: .inbox)
        #expect(noteStore.inboxIndex.count == 3)
        #expect(noteStore.inboxIndex.filter { $0.fileURL == NoteRepositoryMock.TestFile.file1.url }.count == 1)
    }

    @Test func test_canRequestReview_requiresFiveInboxEntries() {
        (0..<4).forEach { _ in
            noteStore.applySaved(NoteData.createTestData())
        }
        #expect(!noteStore.canRequestReview)
        noteStore.applySaved(NoteData.createTestData())
        #expect(noteStore.canRequestReview)
    }

    // MARK: - Cloud updates

    @Test func test_init_registersCloudUpdateHandler() {
        #expect(repositoryMock.cloudUpdateHandler != nil)
    }

    @Test func test_applyCloudUpdate_fetchesIndexWithoutTouchingLoadingState() async {
        #expect(noteStore.isLoading)
        await noteStore.applyCloudUpdate()
        #expect(noteStore.displayInboxEntries.count == 3)
        #expect(noteStore.isLoading)
    }
}

// The canvas save path has its own suite: it feeds the index through
// applySaved rather than enumeration
@MainActor
struct NoteStoreSaveDrawingTests {
    var noteStore: NoteStore
    let repositoryMock: NoteRepositoryMock
    let notes = NoteRepositoryMock.TestFile.allCases.map { NoteData.createTestData(fileURL: $0.url) }

    init() {
        repositoryMock = NoteRepositoryMock(notes: notes)
        noteStore = NoteStore(
            noteRepository: repositoryMock,
            preferenceRepository: PreferenceRepositoryMock(),
            metadataCacheRepository: NoteMetadataCacheRepositoryMock()
        )
    }

    @Test func test_saveDrawing_skipsWhenDrawingUnchanged() {
        let note = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
        var saved: NoteData?
        noteStore.save(drawing: note.entity.drawing, to: note) { saved = $0 }
        #expect(saved == note)
        #expect(noteStore.inboxIndex.isEmpty)
        #expect(repositoryMock.saveCallCount == 0)
    }

    @Test func test_saveDrawing_persistsAndUpdatesIndexOnSuccess() throws {
        let note = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
        let drawing = PKDrawing.stub()
        var result: NoteData?
        noteStore.save(drawing: drawing, to: note) { result = $0 }
        let saved = try #require(result)
        #expect(saved.entity.drawing == drawing)
        #expect(saved.entity.updatedDate > note.entity.updatedDate)
        let entry = try #require(noteStore.inboxIndex.first { $0.fileURL == note.fileURL })
        #expect(entry.updatedDate == saved.entity.updatedDate)
        #expect(noteStore.metadataByFileName[note.fileName]?.id == note.entity.id)
    }

    @Test func test_saveDrawing_returnsNilAndKeepsIndexOnFailure() {
        repositoryMock.saveShouldSucceed = false
        let note = NoteData.createTestData(fileURL: NoteRepositoryMock.TestFile.file1.url)
        var completionCalled = false
        var saved: NoteData?
        noteStore.save(drawing: PKDrawing.stub(), to: note) {
            saved = $0
            completionCalled = true
        }
        #expect(completionCalled)
        #expect(saved == nil)
        #expect(noteStore.inboxIndex.isEmpty)
    }

    @Test func test_saveDrawing_mergesTagsFromMetadataCache() async throws {
        await noteStore.fetch(directory: .inbox)
        let staleSnapshot = notes[0]
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        noteStore.addTag(tag, to: staleSnapshot)

        var result: NoteData?
        noteStore.save(drawing: PKDrawing.stub(), to: staleSnapshot) { result = $0 }

        let saved = try #require(result)
        #expect(saved.entity.tagIds == [tag.id])
        #expect(noteStore.currentTagIds(for: staleSnapshot) == [tag.id])
    }
}
