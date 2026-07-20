//
//  NoteIndexEntryTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2026/07/20.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import Testing
@testable import Pieces_of_Paper

struct NoteIndexEntryTests {
    private let timestampName = "2024-01-02-03-04-051234.pop"
    private let fsCreationDate = Date(timeIntervalSince1970: 1_000)
    private let fsModificationDate = Date(timeIntervalSince1970: 2_000)

    // createdDate comes from the filename timestamp even when fs dates exist
    @Test func createdDate_prefersFileNameTimestamp() throws {
        let expected = try #require(FilePath.parseTimestamp(fromFileName: timestampName))
        let entry = NoteIndexEntry(fileURL: URL(fileURLWithPath: "/notes/\(timestampName)"),
                                   creationDate: fsCreationDate,
                                   contentModificationDate: fsModificationDate)
        #expect(entry.createdDate == expected)
    }

    // Unparseable names fall back to the fs creation date
    @Test func createdDate_fallsBackToFsCreationDate() {
        let entry = NoteIndexEntry(fileURL: URL(fileURLWithPath: "/notes/legacy-note.pop"),
                                   creationDate: fsCreationDate,
                                   contentModificationDate: fsModificationDate)
        #expect(entry.createdDate == fsCreationDate)
    }

    // Without any date source, createdDate degrades to updatedDate's fallback
    @Test func createdDate_fallsBackToUpdatedDate() {
        let entry = NoteIndexEntry(fileURL: URL(fileURLWithPath: "/notes/legacy-note.pop"),
                                   creationDate: nil,
                                   contentModificationDate: fsModificationDate)
        #expect(entry.createdDate == fsModificationDate)
    }

    // updatedDate comes from the fs content-modification date
    @Test func updatedDate_usesContentModificationDate() {
        let entry = NoteIndexEntry(fileURL: URL(fileURLWithPath: "/notes/\(timestampName)"),
                                   creationDate: fsCreationDate,
                                   contentModificationDate: fsModificationDate)
        #expect(entry.updatedDate == fsModificationDate)
    }

    // Missing modification date falls back to the filename timestamp, then fs creation date
    @Test func updatedDate_fallbackChain() throws {
        let parsed = try #require(FilePath.parseTimestamp(fromFileName: timestampName))
        let fromName = NoteIndexEntry(fileURL: URL(fileURLWithPath: "/notes/\(timestampName)"),
                                      creationDate: fsCreationDate,
                                      contentModificationDate: nil)
        #expect(fromName.updatedDate == parsed)

        let fromCreation = NoteIndexEntry(fileURL: URL(fileURLWithPath: "/notes/legacy-note.pop"),
                                          creationDate: fsCreationDate,
                                          contentModificationDate: nil)
        #expect(fromCreation.updatedDate == fsCreationDate)

        let bare = NoteIndexEntry(fileURL: URL(fileURLWithPath: "/notes/legacy-note.pop"),
                                  creationDate: nil,
                                  contentModificationDate: nil)
        #expect(bare.updatedDate == .distantPast)
    }

    @Test func id_isFileURL() {
        let url = URL(fileURLWithPath: "/notes/\(timestampName)")
        let entry = NoteIndexEntry(fileURL: url, creationDate: nil, contentModificationDate: nil)
        #expect(entry.id == url)
    }

    @Test func isArchived_trueForFileUnderArchivedDirectory() throws {
        let archivedUrl = try #require(FilePath.archivedUrl)
        let entry = NoteIndexEntry(fileURL: archivedUrl.appendingPathComponent(timestampName),
                                   creationDate: nil,
                                   contentModificationDate: nil)
        #expect(entry.isArchived)
    }

    @Test func isArchived_falseForFileOutsideArchivedDirectory() throws {
        let inboxUrl = try #require(FilePath.inboxUrl)
        let entry = NoteIndexEntry(fileURL: inboxUrl.appendingPathComponent(timestampName),
                                   creationDate: nil,
                                   contentModificationDate: nil)
        #expect(!entry.isArchived)
    }
}
