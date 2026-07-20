//
//  NoteMetadataCacheRepository.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2026/07/20.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

protocol NoteMetadataCacheRepositoryProtocol: Sendable {
    /// Keyed by file name; see NoteIndexEntry.fileName
    func load() -> [String: NoteMetadata]
    func save(_ entries: [String: NoteMetadata])
}

/// Persists the listing metadata (tags, entity id) learned from document opens
/// so a relaunch does not have to re-open every note to filter by tag.
/// Purely derived data: any read failure just yields an empty cache, which the
/// next opens rebuild.
struct NoteMetadataCacheRepository: NoteMetadataCacheRepositoryProtocol {
    private struct CacheFile: Codable {
        let version: Int
        let entries: [String: NoteMetadata]
    }

    // Bump when the stored shape changes; older files are then discarded
    // instead of decoded into a mismatched struct.
    private static let currentVersion = 1

    private let fileUrl: URL?

    init(fileUrl: URL? = FilePath.noteMetadataCacheFileUrl) {
        self.fileUrl = fileUrl
    }

    func load() -> [String: NoteMetadata] {
        guard let fileUrl,
              let data = try? Data(contentsOf: fileUrl),
              let file = try? JSONDecoder().decode(CacheFile.self, from: data),
              file.version == Self.currentVersion else { return [:] }
        return file.entries
    }

    func save(_ entries: [String: NoteMetadata]) {
        guard let fileUrl else { return }
        let file = CacheFile(version: Self.currentVersion, entries: entries)
        do {
            let data = try JSONEncoder().encode(file)
            try data.write(to: fileUrl, options: .atomic)
        } catch {
            print("Could not write the note metadata cache: ", error.localizedDescription)
        }
    }
}
