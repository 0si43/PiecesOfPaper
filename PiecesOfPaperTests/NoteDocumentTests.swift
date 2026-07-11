//
//  NoteDocumentTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2026/07/11.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import Testing
@testable import Pieces_of_Paper

@MainActor
struct NoteDocumentTests {
    @Test func contents_encodesEntity() throws {
        let document = NoteDocument.createTestData()
        let data = try #require(try document.contents(forType: "") as? Data)
        let decoded = try PropertyListDecoder().decode(NoteEntity.self, from: data)
        #expect(decoded.id == document.entity.id)
    }

    @Test func load_roundTripsEntity() throws {
        let document = NoteDocument.createTestData()
        let data = try #require(try document.contents(forType: "") as? Data)
        let other = NoteDocument.createTestData()
        try other.load(fromContents: data, ofType: nil)
        #expect(other.entity.id == document.entity.id)
    }

    @Test func load_throwsOnGarbageData() {
        let document = NoteDocument.createTestData()
        let originalId = document.entity.id
        #expect(throws: (any Error).self) {
            try document.load(fromContents: Data("not a plist".utf8), ofType: nil)
        }
        #expect(document.entity.id == originalId)
    }

    @Test func load_throwsOnNonDataContents() {
        let document = NoteDocument.createTestData()
        #expect(throws: NoteDocumentError.self) {
            try document.load(fromContents: NSObject(), ofType: nil)
        }
    }
}
