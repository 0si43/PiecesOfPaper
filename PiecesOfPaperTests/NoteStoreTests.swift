//
//  NoteStoreTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2022/05/28.
//  Copyright © 2022 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import Testing
import PencilKit
@testable import Pieces_of_Paper

@MainActor
struct NoteStoreTests {
    var noteStore: NoteStore
    let repositoryMock: NoteRepositoryMock
    let notes = (0...2).map { _ in NoteData.createTestData() }

    init() {
        repositoryMock = NoteRepositoryMock(notes: notes)
        noteStore = NoteStore(
            noteRepository: repositoryMock,
            preferenceRepository: PreferenceRepositoryMock()
        )
    }

    @Test func test_incrementalFetch() async throws {
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.displayInboxNotes == notes.reversed())
    }

    @Test func test_incrementalFetch_skipsUnreadableFileAndShowsError() async {
        repositoryMock.failingUrls = [NoteRepositoryMock.TestFile.file2.url]
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.displayInboxNotes.count == 2)
        #expect(noteStore.showAlert)
    }

    @Test func test_incrementalFetch_retriesFailedFileOnNextFetch() async {
        repositoryMock.failingUrls = [NoteRepositoryMock.TestFile.file2.url]
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.displayInboxNotes.count == 2)

        repositoryMock.failingUrls = []
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.displayInboxNotes.count == 3)
    }

    @Test func test_archive_keepsNoteWhenMoveFails() async {
        await noteStore.incrementalFetch(directory: .inbox)
        repositoryMock.moveShouldThrow = true
        let target = noteStore.displayInboxNotes[0]
        noteStore.archive(target)
        #expect(noteStore.displayInboxNotes.count == 3)
        #expect(noteStore.displayArchivedNotes.isEmpty)
    }

    @Test func test_addTag_persistsTagOnSuccessfulSave() async {
        await noteStore.incrementalFetch(directory: .inbox)
        let target = noteStore.displayInboxNotes[0]
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        noteStore.addTag(tag, to: target)
        #expect(noteStore.note(id: target.id)?.entity.tags == [tag])
        #expect(!noteStore.showAlert)
    }

    @Test func test_addTag_rollsBackTagWhenSaveFails() async {
        await noteStore.incrementalFetch(directory: .inbox)
        repositoryMock.saveShouldSucceed = false
        let target = noteStore.displayInboxNotes[0]
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        noteStore.addTag(tag, to: target)
        #expect(noteStore.note(id: target.id)?.entity.tags.isEmpty == true)
        #expect(noteStore.showAlert)
    }

    @Test func test_noteById_looksUpFetchedNote() async {
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.note(id: notes[1].id) == notes[1])
        #expect(noteStore.note(id: UUID()) == nil)
    }

    @Test func test_upsert_replacesExistingNote() async {
        await noteStore.incrementalFetch(directory: .inbox)
        var updated = notes[0]
        updated.entity.updatedDate = Date()
        noteStore.upsert(updated)
        #expect(noteStore.note(id: updated.id) == updated)
        #expect(noteStore.inboxNotes.count == 3)
    }

    @Test func test_upsert_insertsUnknownNoteIntoInbox() {
        let note = NoteData.createTestData()
        noteStore.upsert(note)
        #expect(noteStore.inboxNotes == [note])
    }

    @Test func test_upsert_thenIncrementalFetchDoesNotDuplicate() async {
        let note = NoteData(entity: NoteEntity(drawing: PKDrawing()),
                            fileURL: NoteRepositoryMock.TestFile.file1.url)
        noteStore.upsert(note)
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.inboxNotes.count == 3)
        #expect(noteStore.inboxNotes.filter { $0.fileURL == NoteRepositoryMock.TestFile.file1.url }.count == 1)
    }
}

final class NoteRepositoryMock: NoteRepositoryProtocol {
    enum TestFile: CaseIterable {
        case file1, file2, file3

        // swiftlint:disable force_unwrapping
        var url: URL {
            switch self {
            case .file1:
                URL(string: "file:///path/to/file1")!
            case .file2:
                URL(string: "file:///path/to/file2")!
            case .file3:
                URL(string: "file:///path/to/file3")!
            }
        }
        // swiftlint:enable force_unwrapping
    }

    var notes: [NoteData]
    var failingUrls: Set<URL> = []
    var moveShouldThrow = false

    init(notes: [NoteData]) {
        self.notes = notes
    }

    func getFileUrls(directory: NoteDirectory) -> [URL] {
        TestFile.allCases.map { $0.url }
    }

    @MainActor
    func open(fileUrl: URL) async throws -> NoteData {
        if failingUrls.contains(fileUrl) {
            throw NoteRepositoryError.fileOpenFailed(path: fileUrl.path)
        }
        switch fileUrl.lastPathComponent {
        case "file1":
            return notes[0]
        case "file2":
            return notes[1]
        case "file3":
            return notes[2]
        default:
            fatalError()
        }
    }

    var saveShouldSucceed = true
    func save(_ entity: NoteEntity, to fileUrl: URL, completion: @escaping (Bool) -> Void) {
        completion(saveShouldSucceed)
    }

    func delete(fileUrl: URL) throws {}

    func move(fileUrl: URL, to directory: NoteDirectory) throws -> URL {
        if moveShouldThrow {
            throw NoteRepositoryError.directoryNotAvailable
        }
        return fileUrl
    }

    func duplicate(_ note: NoteData, in directory: NoteDirectory,
                   completion: @escaping (NoteData?) -> Void) {
        completion(nil)
    }
}

struct PreferenceRepositoryMock: PreferenceRepositoryProtocol {
    func getEnablediCloud() -> Bool { false }
    func setEnablediCloud(_ value: Bool) {}
    func getEnabledAutoSave() -> Bool { true }
    func setEnabledAutoSave(_ value: Bool) {}
    func getEnabledInfiniteScroll() -> Bool { true }
    func setEnabledInfiniteScroll(_ value: Bool) {}
    func getListOrder(directoryName: String) -> ListOrder { ListOrder() }
    func setListOrder(directoryName: String, listOrder: ListOrder) {}
}
