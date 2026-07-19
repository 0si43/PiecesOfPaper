//
//  NoteRepositoryTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2026/07/19.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Testing
import Foundation
import PencilKit
@testable import Pieces_of_Paper

@MainActor
struct NoteRepositoryTests {
    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NoteRepositoryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func save(_ entity: NoteEntity, to fileUrl: URL,
                      with repository: NoteRepository) async -> Bool {
        await withCheckedContinuation { continuation in
            repository.save(entity, to: fileUrl) { continuation.resume(returning: $0) }
        }
    }

    @Test func save_retargetsStaleLegacyUrlToMigratedFile() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let migratedUrl = directory.appendingPathComponent("note.pop")
        try PropertyListEncoder().encode(NoteEntity(drawing: PKDrawing())).write(to: migratedUrl)
        let staleUrl = directory.appendingPathComponent("note.plist")
        let entity = NoteEntity(drawing: PKDrawing())

        let success = await save(entity, to: staleUrl, with: NoteRepository())

        #expect(success)
        #expect(!FileManager.default.fileExists(atPath: staleUrl.path))
        let saved = try PropertyListDecoder().decode(NoteEntity.self,
                                                     from: Data(contentsOf: migratedUrl))
        #expect(saved.id == entity.id)
    }

    @Test func save_writesToLegacyUrlWhileItStillExists() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let legacyUrl = directory.appendingPathComponent("note.plist")
        try PropertyListEncoder().encode(NoteEntity(drawing: PKDrawing())).write(to: legacyUrl)
        let entity = NoteEntity(drawing: PKDrawing())

        let success = await save(entity, to: legacyUrl, with: NoteRepository())

        #expect(success)
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("note.pop").path))
        let saved = try PropertyListDecoder().decode(NoteEntity.self,
                                                     from: Data(contentsOf: legacyUrl))
        #expect(saved.id == entity.id)
    }
}
