//
//  NoteViewModelTest.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2022/05/28.
//  Copyright © 2022 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import Testing
@testable import Pieces_of_Paper

@MainActor
struct NoteViewModelTest {
    var viewModel: NoteViewModel
    let documents = (0...2).map { _ in NoteDocument.createTestData() }
    init() {
        viewModel = NoteViewModel(documentStore: DocumentStoreMock(documents: documents))
    }

    @Test func test_incrementalFetch() async throws {
        await viewModel.incrementalFetch()
        #expect(viewModel.displayNoteDocuments == documents.reversed())
    }
}

final class DocumentStoreMock: DocumentStoreProtocol {
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
    var directory: DocumentStore.TargetDirectory = .inbox
    var documents: [NoteDocument]

    init(documents: [NoteDocument]) {
        self.documents = documents
    }

    func getFileUrls() -> [URL] {
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

}
