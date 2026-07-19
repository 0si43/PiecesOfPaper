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
    let preferenceRepositoryMock: PreferenceRepositoryMock
    let notes = (0...2).map { _ in NoteData.createTestData() }

    init() {
        repositoryMock = NoteRepositoryMock(notes: notes)
        preferenceRepositoryMock = PreferenceRepositoryMock()
        noteStore = NoteStore(
            noteRepository: repositoryMock,
            preferenceRepository: preferenceRepositoryMock
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
            preferenceRepository: preferenceMock
        )
        #expect(store.inboxListOrder.sortBy == .createdDate)
        #expect(store.archivedListOrder.sortOrder == .ascending)
        #expect(preferenceMock.setListOrderCalls.isEmpty)
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

    @Test func test_upsert_insertsUnknownArchivedNoteIntoArchivedList() throws {
        let archivedUrl = try #require(FilePath.archivedUrl).appendingPathComponent("archived-note.plist")
        let note = NoteData(entity: NoteEntity(drawing: PKDrawing()), fileURL: archivedUrl)
        noteStore.upsert(note)
        #expect(noteStore.archivedNotes == [note])
        #expect(noteStore.inboxNotes.isEmpty)
    }

    private func makeDrawing() -> PKDrawing {
        let point = PKStrokePoint(location: .zero,
                                  timeOffset: 0,
                                  size: CGSize(width: 1, height: 1),
                                  opacity: 1,
                                  force: 1,
                                  azimuth: 0,
                                  altitude: 0)
        let path = PKStrokePath(controlPoints: [point], creationDate: Date())
        return PKDrawing(strokes: [PKStroke(ink: PKInk(.pen, color: .black), path: path)])
    }

    @Test func test_saveDrawing_skipsWhenDrawingUnchanged() {
        let note = NoteData.createTestData()
        var saved: NoteData?
        noteStore.save(drawing: note.entity.drawing, to: note) { saved = $0 }
        #expect(saved == note)
        #expect(noteStore.inboxNotes.isEmpty)
    }

    @Test func test_saveDrawing_persistsAndUpsertsOnSuccess() throws {
        let note = NoteData.createTestData()
        let drawing = makeDrawing()
        var result: NoteData?
        noteStore.save(drawing: drawing, to: note) { result = $0 }
        let saved = try #require(result)
        #expect(saved.entity.drawing == drawing)
        #expect(saved.entity.updatedDate > note.entity.updatedDate)
        #expect(noteStore.note(id: note.id) == saved)
    }

    @Test func test_saveDrawing_returnsNilAndKeepsStoreOnFailure() {
        repositoryMock.saveShouldSucceed = false
        let note = NoteData.createTestData()
        var completionCalled = false
        var saved: NoteData?
        noteStore.save(drawing: makeDrawing(), to: note) {
            saved = $0
            completionCalled = true
        }
        #expect(completionCalled)
        #expect(saved == nil)
        #expect(noteStore.note(id: note.id) == nil)
    }

    @Test func test_saveDrawing_basesPayloadOnStoreCopyNotStaleSnapshot() async throws {
        await noteStore.incrementalFetch(directory: .inbox)
        let staleSnapshot = notes[0]
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        noteStore.addTag(tag, to: staleSnapshot)

        var result: NoteData?
        noteStore.save(drawing: makeDrawing(), to: staleSnapshot) { result = $0 }

        let saved = try #require(result)
        #expect(saved.entity.tags == [tag])
        #expect(noteStore.note(id: staleSnapshot.id)?.entity.tags == [tag])
    }

    @Test func test_saveDrawing_skipsWhenStoreCopyAlreadyHasDrawing() async {
        await noteStore.incrementalFetch(directory: .inbox)
        let staleSnapshot = notes[0]
        let drawing = makeDrawing()
        var first: NoteData?
        noteStore.save(drawing: drawing, to: staleSnapshot) { first = $0 }
        let callsAfterFirst = repositoryMock.saveCallCount

        var second: NoteData?
        noteStore.save(drawing: drawing, to: staleSnapshot) { second = $0 }

        #expect(second == first)
        #expect(repositoryMock.saveCallCount == callsAfterFirst)
    }

    @Test func test_canRequestReview_requiresFiveInboxNotes() {
        (0..<4).forEach { _ in noteStore.upsert(NoteData.createTestData()) }
        #expect(!noteStore.canRequestReview)
        noteStore.upsert(NoteData.createTestData())
        #expect(noteStore.canRequestReview)
    }

    @Test func test_init_registersCloudUpdateHandler() {
        #expect(repositoryMock.cloudUpdateHandler != nil)
    }

    @Test func test_applyCloudUpdate_fetchesNotesWithoutTouchingLoadingState() async {
        #expect(noteStore.isLoading)
        await noteStore.applyCloudUpdate()
        #expect(noteStore.displayInboxNotes.count == 3)
        #expect(noteStore.isLoading)
    }

    @Test func test_applyCloudUpdate_suppressesErrorAlertAndRetriesLater() async {
        repositoryMock.failingUrls = [NoteRepositoryMock.TestFile.file2.url]
        await noteStore.applyCloudUpdate()
        #expect(noteStore.displayInboxNotes.count == 2)
        #expect(!noteStore.showAlert)

        repositoryMock.failingUrls = []
        await noteStore.applyCloudUpdate()
        #expect(noteStore.displayInboxNotes.count == 3)
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
    var fileUrls: [URL]?
    private(set) var cloudUpdateHandler: (@MainActor () -> Void)?

    init(notes: [NoteData]) {
        self.notes = notes
    }

    @MainActor
    func getFileUrls(directory: NoteDirectory) async -> [URL] {
        guard directory == .inbox else { return [] }
        return fileUrls ?? TestFile.allCases.map { $0.url }
    }

    @MainActor
    func setCloudUpdateHandler(_ handler: @escaping @MainActor () -> Void) {
        cloudUpdateHandler = handler
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
    private(set) var saveCallCount = 0
    func save(_ entity: NoteEntity, to fileUrl: URL, completion: @escaping (Bool) -> Void) {
        saveCallCount += 1
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

final class PreferenceRepositoryMock: PreferenceRepositoryProtocol {
    var enablediCloud = false
    var enabledAutoSave = true
    var enabledInfiniteScroll = true
    var listOrders: [String: ListOrder] = [:]
    private(set) var setEnablediCloudCalls: [Bool] = []
    private(set) var setEnabledAutoSaveCalls: [Bool] = []
    private(set) var setEnabledInfiniteScrollCalls: [Bool] = []
    private(set) var setListOrderCalls: [(directoryName: String, listOrder: ListOrder)] = []

    func getEnablediCloud() -> Bool { enablediCloud }

    func setEnablediCloud(_ value: Bool) {
        enablediCloud = value
        setEnablediCloudCalls.append(value)
    }

    func getEnabledAutoSave() -> Bool { enabledAutoSave }

    func setEnabledAutoSave(_ value: Bool) {
        enabledAutoSave = value
        setEnabledAutoSaveCalls.append(value)
    }

    func getEnabledInfiniteScroll() -> Bool { enabledInfiniteScroll }

    func setEnabledInfiniteScroll(_ value: Bool) {
        enabledInfiniteScroll = value
        setEnabledInfiniteScrollCalls.append(value)
    }

    func getListOrder(directoryName: String) -> ListOrder {
        listOrders[directoryName] ?? ListOrder()
    }

    func setListOrder(directoryName: String, listOrder: ListOrder) {
        listOrders[directoryName] = listOrder
        setListOrderCalls.append((directoryName, listOrder))
    }
}
