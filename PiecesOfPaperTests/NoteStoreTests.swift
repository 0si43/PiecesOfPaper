import UIKit
import Testing
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

    @Test func test_fetch_coalescesOverlappingFetchesForTheSameDirectory() async {
        repositoryMock.suspendGetFileAttributes = true

        async let first: Void = noteStore.fetch(directory: .inbox)
        async let second: Void = noteStore.fetch(directory: .inbox)
        await waitUntil { repositoryMock.hasPendingGetFileAttributes }
        repositoryMock.suspendGetFileAttributes = false
        repositoryMock.resumePendingGetFileAttributes()
        _ = await (first, second)

        #expect(repositoryMock.getFileAttributesCallCount == 1)
        #expect(noteStore.inboxIndex.count == 3)
    }

    @Test func test_fetch_runsAgainAfterThePreviousFetchCompletes() async {
        await noteStore.fetch(directory: .inbox)
        await noteStore.fetch(directory: .inbox)
        #expect(repositoryMock.getFileAttributesCallCount == 2)
    }

    @Test func test_fetch_foregroundJoinerShowsSpinnerWhileJoinedBackgroundFetchRuns() async {
        // isLoading starts true; the initial foreground fetch settles it to false
        await noteStore.fetch(directory: .inbox)
        repositoryMock.suspendGetFileAttributes = true

        async let backgroundFetch: Void = noteStore.fetch(directory: .inbox, background: true)
        await waitUntil { repositoryMock.hasPendingGetFileAttributes }
        #expect(!noteStore.isLoading)

        async let foregroundFetch: Void = noteStore.fetch(directory: .inbox)
        await waitUntil { noteStore.isLoading }
        #expect(noteStore.isLoading)

        repositoryMock.suspendGetFileAttributes = false
        repositoryMock.resumePendingGetFileAttributes()
        _ = await (backgroundFetch, foregroundFetch)

        #expect(!noteStore.isLoading)
        #expect(repositoryMock.getFileAttributesCallCount == 2)
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

        try await noteStore.addTag(tag, to: notes[0])
        #expect(noteStore.displayInboxEntries.map(\.fileURL) == [notes[0].fileURL])
    }

    // MARK: - Lazy note loading

    @Test func test_loadNote_cachesMetadataAndRetriesAfterFailure() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        repositoryMock.failingUrls = [entry.fileURL]

        let failed = await noteStore.loadNote(entry)
        #expect(failed == nil)
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
