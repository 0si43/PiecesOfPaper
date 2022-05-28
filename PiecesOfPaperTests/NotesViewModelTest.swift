//
//  NotesViewModelTest.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2022/05/28.
//  Copyright © 2022 Tsuyoshi Nakajima. All rights reserved.
//

import PencilKit
import XCTest
@testable import Pieces_of_Paper

class NotesViewModelTest: XCTestCase {
    var viewModel: NotesViewModel!
    var document: NoteDocument!

    override func setUpWithError() throws {
        try? super.setUpWithError()
        viewModel = .init(targetDirectory: .inbox)
        document = NoteDocument.createTestData()
    }

    func test_share() throws {
        XCTAssertFalse(viewModel.showActivityView)
        viewModel.share(document)
        XCTAssertEqual(viewModel.documentToShare, document)
        XCTAssertTrue(viewModel.showActivityView)
    }
}
