//
//  CanvasViewModelTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2026/07/18.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import Testing
import PencilKit
@testable import Pieces_of_Paper

@MainActor
struct CanvasViewModelTests {
    let repositoryMock = NoteRepositoryMock(notes: [])
    let viewModel: CanvasViewModel

    init() {
        viewModel = CanvasViewModel(note: NoteData.createTestData(), noteRepository: repositoryMock)
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

    @Test func hasUnsavedChanges_detectsDrawingDifference() {
        #expect(!viewModel.hasUnsavedChanges(comparedTo: viewModel.note.entity.drawing))
        #expect(viewModel.hasUnsavedChanges(comparedTo: makeDrawing()))
    }

    @Test func save_skipsWhenDrawingUnchanged() {
        var persisted: NoteData?
        viewModel.onPersisted = { persisted = $0 }
        let originalUpdatedDate = viewModel.note.entity.updatedDate

        var completionResult: Bool?
        viewModel.save(drawing: viewModel.note.entity.drawing) { completionResult = $0 }

        #expect(completionResult == true)
        #expect(persisted == nil)
        #expect(viewModel.note.entity.updatedDate == originalUpdatedDate)
    }

    @Test func save_updatesDrawingAndDateOnSuccess() {
        let drawing = makeDrawing()
        let originalUpdatedDate = viewModel.note.entity.updatedDate

        viewModel.save(drawing: drawing)

        #expect(viewModel.note.entity.drawing == drawing)
        #expect(viewModel.note.entity.updatedDate > originalUpdatedDate)
        #expect(!viewModel.showSaveFailedAlert)
    }

    @Test func save_notifiesPersistedNoteOnSuccess() {
        var persisted: NoteData?
        viewModel.onPersisted = { persisted = $0 }
        let drawing = makeDrawing()

        viewModel.save(drawing: drawing)

        #expect(persisted == viewModel.note)
        #expect(persisted?.entity.drawing == drawing)
    }

    @Test func save_flagsAlertAndSkipsCallbackOnFailure() {
        repositoryMock.saveShouldSucceed = false
        var persisted: NoteData?
        viewModel.onPersisted = { persisted = $0 }

        var completionResult: Bool?
        viewModel.save(drawing: makeDrawing()) { completionResult = $0 }

        #expect(completionResult == false)
        #expect(persisted == nil)
        #expect(viewModel.showSaveFailedAlert)
    }
}
