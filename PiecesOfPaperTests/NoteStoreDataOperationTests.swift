import UIKit
import Testing
@testable import Pieces_of_Paper

@MainActor
struct NoteStoreDataOperationTests {
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

    /// Delete and move run on the store's internal task chain, so assertions
    /// have to let it drain first.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<100 where !condition() {
            await Task.yield()
        }
    }

    @Test func test_duplicate_appendsEntryForTheNewFile() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        try await noteStore.duplicate(entry, in: .inbox)
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
        try await noteStore.delete(entry)
        #expect(noteStore.inboxIndex.count == 2)
        #expect(noteStore.metadataByFileName[entry.fileName] == nil)
    }

    @Test func test_delete_restoresEntryAndThrowsWhenDeleteFails() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        repositoryMock.deleteShouldThrow = true

        await #expect(throws: NoteStoreError.deleteFailed) {
            try await noteStore.delete(entry)
        }

        #expect(noteStore.inboxIndex.count == 3)
        #expect(noteStore.inboxIndex.contains { $0.fileURL == entry.fileURL })
    }

    @Test func test_delete_ignoresARepeatedTapForTheSameEntry() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)

        try await noteStore.delete(entry)
        try await noteStore.delete(entry)

        #expect(repositoryMock.deletedUrls == [entry.fileURL])
        #expect(noteStore.inboxIndex.count == 2)
    }

    @Test func test_fetch_doesNotResurrectAnEntryWhileItsDeleteIsInFlight() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        repositoryMock.suspendFileOperations = true

        async let deletion: Void = noteStore.delete(entry)
        await waitUntil { repositoryMock.hasPendingFileOperation }
        // Enumeration still reports the file: the removal has not landed yet
        await noteStore.fetch(directory: .inbox)

        #expect(!noteStore.inboxIndex.contains { $0.fileURL == entry.fileURL })

        repositoryMock.resumePendingFileOperations()
        try await deletion
        #expect(noteStore.inboxIndex.count == 2)
    }

    @Test func test_archive_movesEntryAndKeepsMetadataWithoutReopening() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        _ = await noteStore.loadNote(entry)

        try await noteStore.archive(entry)

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
        await #expect(throws: NoteStoreError.moveFailed) {
            try await noteStore.archive(target)
        }
        #expect(noteStore.displayInboxEntries.count == 3)
        #expect(noteStore.displayArchivedEntries.isEmpty)
    }

    @Test func test_allArchive_movesEveryEntryInOrder() async throws {
        await noteStore.fetch(directory: .inbox)
        let urls = noteStore.inboxIndex.map(\.fileURL)

        try await noteStore.allArchive()

        #expect(repositoryMock.movedUrls == urls)
        #expect(noteStore.inboxIndex.isEmpty)
        #expect(noteStore.archivedIndex.count == urls.count)
    }

    @Test func test_allArchive_movesRemainingNotesAndThrowsAggregateErrorWhenOneMoveFails() async {
        await noteStore.fetch(directory: .inbox)
        let failingUrl = NoteRepositoryMock.TestFile.file2.url
        repositoryMock.moveFailingUrls = [failingUrl]

        await #expect(throws: NoteStoreError.bulkMoveFailed(count: 1)) {
            try await noteStore.allArchive()
        }

        #expect(noteStore.inboxIndex.map(\.fileURL) == [failingUrl])
        #expect(noteStore.archivedIndex.count == 2)
    }

    @Test func test_allArchive_reportsTotalCountWhenEveryMoveFails() async {
        await noteStore.fetch(directory: .inbox)
        repositoryMock.moveShouldThrow = true

        await #expect(throws: NoteStoreError.bulkMoveFailed(count: 3)) {
            try await noteStore.allArchive()
        }

        #expect(noteStore.inboxIndex.count == 3)
        #expect(noteStore.archivedIndex.isEmpty)
    }

    @Test func test_allUnarchive_throwsAggregateErrorWhenAMoveFails() async throws {
        await noteStore.fetch(directory: .inbox)
        try await noteStore.allArchive()
        let archivedUrl = try #require(noteStore.archivedIndex.first?.fileURL)
        repositoryMock.moveFailingUrls = [archivedUrl]

        await #expect(throws: NoteStoreError.bulkMoveFailed(count: 1)) {
            try await noteStore.allUnarchive()
        }

        #expect(noteStore.archivedIndex.map(\.fileURL) == [archivedUrl])
        #expect(noteStore.inboxIndex.count == 2)
    }

    // MARK: - Tag operations

    @Test func test_addTag_updatesMetadataOnSuccessfulSave() async throws {
        await noteStore.fetch(directory: .inbox)
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        try await noteStore.addTag(tag, to: notes[0])
        #expect(noteStore.currentTagIds(for: notes[0]) == [tag.id])
    }

    @Test func test_addTag_rollsBackTagWhenSaveFails() async {
        await noteStore.fetch(directory: .inbox)
        repositoryMock.saveShouldSucceed = false
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        await #expect(throws: NoteStoreError.saveFailed) {
            try await noteStore.addTag(tag, to: notes[0])
        }
        #expect(noteStore.currentTagIds(for: notes[0]).isEmpty)
    }
}
