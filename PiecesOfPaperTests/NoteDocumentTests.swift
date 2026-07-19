//
//  NoteDocumentTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2026/07/11.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import Testing
import PencilKit
@testable import Pieces_of_Paper

@MainActor
struct NoteDocumentTests {
    private func makeDocument(drawing: PKDrawing = PKDrawing()) -> NoteDocument {
        guard let url = URL(string: "file:///test") else {
            fatalError()
        }

        return NoteDocument(fileURL: url, entity: NoteEntity(drawing: drawing))
    }

    @Test func contents_encodesEntity() throws {
        let document = makeDocument()
        let data = try #require(try document.contents(forType: "") as? Data)
        let decoded = try PropertyListDecoder().decode(NoteEntity.self, from: data)
        #expect(decoded.id == document.entity.id)
    }

    @Test func load_roundTripsEntity() throws {
        let document = makeDocument()
        let data = try #require(try document.contents(forType: "") as? Data)
        let other = makeDocument()
        try other.load(fromContents: data, ofType: nil)
        #expect(other.entity.id == document.entity.id)
    }

    @Test func load_roundTripsNonEmptyDrawing() throws {
        let document = makeDocument(drawing: .stub())
        let data = try #require(try document.contents(forType: "") as? Data)
        let other = makeDocument()
        try other.load(fromContents: data, ofType: nil)
        #expect(!other.entity.drawing.strokes.isEmpty)
        #expect(other.entity.drawing == document.entity.drawing)
    }

    @Test func load_throwsOnGarbageData() {
        let document = makeDocument()
        let originalId = document.entity.id
        #expect(throws: (any Error).self) {
            try document.load(fromContents: Data("not a plist".utf8), ofType: nil)
        }
        #expect(document.entity.id == originalId)
    }

    @Test func load_throwsOnNonDataContents() {
        let document = makeDocument()
        #expect(throws: NoteDocumentError.self) {
            try document.load(fromContents: NSObject(), ofType: nil)
        }
    }
}
