//
//  NoteViewModelTest.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2022/05/28.
//  Copyright © 2022 Tsuyoshi Nakajima. All rights reserved.
//

import Testing
@testable import Pieces_of_Paper

@MainActor
struct NoteViewModelTest {
    var viewModel: NoteViewModel
    init() {
        viewModel = NoteViewModel(targetDirectory: .inbox)
    }

    @Test func sample() {
        #expect(viewModel.isTargetDirectoryInbox)
    }
}
