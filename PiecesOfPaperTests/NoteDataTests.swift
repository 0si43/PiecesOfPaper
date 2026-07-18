//
//  NoteDataTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2026/07/18.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import Testing
import PencilKit
@testable import Pieces_of_Paper

struct NoteDataTests {
    @Test func id_delegatesToEntityId() {
        let note = NoteData.createTestData()
        #expect(note.id == note.entity.id)
    }

    @Test func isArchived_trueForFileUnderArchivedDirectory() throws {
        let archivedUrl = try #require(FilePath.archivedUrl)
        let note = NoteData(entity: NoteEntity(drawing: PKDrawing()),
                            fileURL: archivedUrl.appendingPathComponent("test.plist"))
        #expect(note.isArchived)
    }

    @Test func isArchived_falseForFileOutsideArchivedDirectory() throws {
        let inboxUrl = try #require(FilePath.inboxUrl)
        let note = NoteData(entity: NoteEntity(drawing: PKDrawing()),
                            fileURL: inboxUrl.appendingPathComponent("test.plist"))
        #expect(!note.isArchived)
    }

    @Test func equatable_detectsEntityChange() {
        let note = NoteData.createTestData()
        var modified = note
        #expect(note == modified)
        modified.entity.tags.append(TagEntity(name: "tag", color: CodableUIColor(uiColor: .red)))
        #expect(note != modified)
    }
}
