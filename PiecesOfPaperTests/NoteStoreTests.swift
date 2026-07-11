//
//  NoteStoreTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2022/05/28.
//  Copyright © 2022 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import Testing
@testable import Pieces_of_Paper

@MainActor
struct NoteStoreTests {
    var noteStore: NoteStore
    let repositoryMock: NoteRepositoryMock
    let documents = (0...2).map { _ in NoteDocument.createTestData() }

    init() {
        repositoryMock = NoteRepositoryMock(documents: documents)
        noteStore = NoteStore(
            noteRepository: repositoryMock,
            preferenceRepository: PreferenceRepositoryMock()
        )
    }

    @Test func test_incrementalFetch() async throws {
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.displayInboxDocuments == documents.reversed())
    }

    @Test func test_incrementalFetch_skipsUnreadableFileAndShowsError() async {
        repositoryMock.failingUrls = [NoteRepositoryMock.TestFile.file2.url]
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.displayInboxDocuments.count == 2)
        #expect(noteStore.showAlert)
    }

    @Test func test_incrementalFetch_retriesFailedFileOnNextFetch() async {
        repositoryMock.failingUrls = [NoteRepositoryMock.TestFile.file2.url]
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.displayInboxDocuments.count == 2)

        repositoryMock.failingUrls = []
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.displayInboxDocuments.count == 3)
    }

    @Test func test_archive_keepsDocumentWhenMoveFails() async {
        await noteStore.incrementalFetch(directory: .inbox)
        repositoryMock.moveShouldThrow = true
        let target = noteStore.displayInboxDocuments[0]
        noteStore.archive(target)
        #expect(noteStore.displayInboxDocuments.count == 3)
        #expect(noteStore.displayArchivedDocuments.isEmpty)
    }

    @Test func test_addTag_persistsTagOnSuccessfulSave() async {
        await noteStore.incrementalFetch(directory: .inbox)
        let target = noteStore.displayInboxDocuments[0]
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        noteStore.addTag(tag, to: target)
        #expect(target.entity.tags == [tag])
        #expect(!noteStore.showAlert)
    }

    @Test func test_addTag_rollsBackTagWhenSaveFails() async {
        await noteStore.incrementalFetch(directory: .inbox)
        repositoryMock.saveShouldSucceed = false
        let target = noteStore.displayInboxDocuments[0]
        let tag = TagEntity(name: "test", color: CodableUIColor(uiColor: .red))
        noteStore.addTag(tag, to: target)
        #expect(target.entity.tags.isEmpty)
        #expect(noteStore.showAlert)
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

    var documents: [NoteDocument]
    var failingUrls: Set<URL> = []
    var moveShouldThrow = false

    init(documents: [NoteDocument]) {
        self.documents = documents
    }

    func getFileUrls(directory: NoteDirectory) -> [URL] {
        TestFile.allCases.map { $0.url }
    }

    @MainActor
    func open(fileUrl: URL) async throws -> NoteDocument {
        if failingUrls.contains(fileUrl) {
            throw NoteRepositoryError.fileOpenFailed(path: fileUrl.path)
        }
        switch fileUrl.lastPathComponent {
        case "file1":
            return documents[0]
        case "file2":
            return documents[1]
        case "file3":
            return documents[2]
        default:
            fatalError()
        }
    }

    var saveShouldSucceed = true
    func save(document: NoteDocument, completion: @escaping (Bool) -> Void) {
        completion(saveShouldSucceed)
    }

    func delete(fileUrl: URL) throws {}

    func move(fileUrl: URL, to directory: NoteDirectory) throws -> URL {
        if moveShouldThrow {
            throw NoteRepositoryError.directoryNotAvailable
        }
        return fileUrl
    }

    func duplicate(document: NoteDocument, in directory: NoteDirectory,
                   completion: @escaping (NoteDocument?) -> Void) {
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
