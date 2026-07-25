import Testing
@testable import Pieces_of_Paper

/// iCloud-specific error surfacing: download-failure propagation and the
/// mid-session cloud→local fallback flag (issue #224).
@MainActor
struct NoteStoreCloudErrorTests {
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

    // MARK: - Download-failure propagation

    @Test func test_loadNoteResult_propagatesNotDownloadedError() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        repositoryMock.openErrors = [entry.fileURL: NoteRepositoryError.fileNotDownloaded(path: entry.fileURL.path)]

        let result = await noteStore.loadNoteResult(entry)
        guard case .failure(let error) = result else {
            Issue.record("expected failure")
            return
        }
        guard case NoteRepositoryError.fileNotDownloaded = error else {
            Issue.record("expected fileNotDownloaded, got \(error)")
            return
        }
        #expect(await noteStore.loadNote(entry) == nil)
    }

    @Test func test_openFailure_mapsNotDownloadedToDownloadFailed() {
        let downloadError = NoteRepositoryError.fileNotDownloaded(path: "/a.pop")
        #expect(NoteStoreError.openFailure(from: downloadError, count: 2) == .downloadFailed(count: 2))

        let corruptError = NoteRepositoryError.fileOpenFailed(path: "/a.pop")
        #expect(NoteStoreError.openFailure(from: corruptError, count: 1) == .openFailed(count: 1))

        #expect(NoteStoreError.downloadFailed(count: 1).errorDescription?.contains("network") == true)
        #expect(NoteStoreError.openFailed(count: 1).errorDescription?.contains("downloaded") == false)
    }

    @Test func test_duplicate_throwsDownloadFailedWhenNoteIsNotDownloaded() async throws {
        await noteStore.fetch(directory: .inbox)
        let entry = try #require(noteStore.inboxIndex.first)
        repositoryMock.openErrors = [entry.fileURL: NoteRepositoryError.fileNotDownloaded(path: entry.fileURL.path)]
        await #expect(throws: NoteStoreError.downloadFailed(count: 1)) {
            try await noteStore.duplicate(entry, in: .inbox)
        }

        repositoryMock.openErrors = [:]
        repositoryMock.failingUrls = [entry.fileURL]
        await #expect(throws: NoteStoreError.openFailed(count: 1)) {
            try await noteStore.duplicate(entry, in: .inbox)
        }
    }

    // MARK: - Mid-session storage fallback

    @Test func test_fetch_flagsFallbackWhenCloudBecomesUnavailable() async {
        preferenceRepositoryMock.enablediCloud = true
        repositoryMock.isCloudStorageActive = true
        await noteStore.fetch(directory: .inbox)
        #expect(!noteStore.didFallBackToLocalStorage)

        repositoryMock.isCloudStorageActive = false
        await noteStore.fetch(directory: .inbox)
        #expect(noteStore.didFallBackToLocalStorage)

        noteStore.acknowledgeLocalStorageFallback()
        #expect(!noteStore.didFallBackToLocalStorage)
    }

    @Test func test_fetch_doesNotFlagFallbackWhenUserDisablediCloud() async {
        preferenceRepositoryMock.enablediCloud = true
        repositoryMock.isCloudStorageActive = true
        await noteStore.fetch(directory: .inbox)

        preferenceRepositoryMock.enablediCloud = false
        repositoryMock.isCloudStorageActive = false
        await noteStore.fetch(directory: .inbox)
        #expect(!noteStore.didFallBackToLocalStorage)
    }

    @Test func test_fetch_doesNotFlagFallbackOnFirstFetchOrRecovery() async {
        preferenceRepositoryMock.enablediCloud = true
        repositoryMock.isCloudStorageActive = false
        await noteStore.fetch(directory: .inbox)
        #expect(!noteStore.didFallBackToLocalStorage)

        repositoryMock.isCloudStorageActive = true
        await noteStore.fetch(directory: .inbox)
        #expect(!noteStore.didFallBackToLocalStorage)
    }
}
