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
    let documents = (0...2).map { _ in NoteDocument.createTestData() }

    init() {
        noteStore = NoteStore(
            noteRepository: NoteRepositoryMock(documents: documents),
            preferenceRepository: PreferenceRepositoryMock()
        )
    }

    func add(a: Int, b: Int) -> Int { a + b }

    @Test func test_add() {
        let result = add(a: 1, b: 1)
        #expect(result == 2)
    }

    @Test func test_incrementalFetch() async throws {
        await noteStore.incrementalFetch(directory: .inbox)
        #expect(noteStore.displayInboxDocuments == documents.reversed())
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

    init(documents: [NoteDocument]) {
        self.documents = documents
    }

    func getFileUrls(directory: NoteDirectory) -> [URL] {
        TestFile.allCases.map { $0.url }
    }

    @MainActor
    func open(fileUrl: URL) async throws -> NoteDocument {
        switch fileUrl.lastPathComponent {
        case "file1":
            documents[0]
        case "file2":
            documents[1]
        case "file3":
            documents[2]
        default:
            fatalError()
        }
    }

    func save(document: NoteDocument) {}

    func save(document: NoteDocument, for saveOperation: UIDocument.SaveOperation) {}

    func delete(fileUrl: URL) throws {}

    func move(fileUrl: URL, to directory: NoteDirectory) throws -> URL {
        fileUrl
    }

    func duplicate(document: NoteDocument, in directory: NoteDirectory) -> NoteDocument? {
        nil
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
