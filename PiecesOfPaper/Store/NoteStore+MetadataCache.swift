//
//  NoteStore+MetadataCache.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2026/07/20.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

// MARK: - Metadata cache persistence

extension NoteStore {
    private static var persistDebounce: Duration { .seconds(1) }

    func makePersistedMetadataLoad() -> Task<Void, Never> {
        Task { [metadataCacheRepository] in
            let persisted = await Task.detached { metadataCacheRepository.load() }.value
            // Opens that landed while the file was being read are newer than
            // anything on disk, so they win
            metadataByFileName.merge(persisted) { current, _ in current }
        }
    }

    /// Coalesces writes: hydrating a tag filter records hundreds of entries in
    /// a burst and only the last state has to reach the disk.
    func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task {
            try? await Task.sleep(for: Self.persistDebounce)
            guard !Task.isCancelled else { return }
            await writeMetadataCache()
        }
    }

    /// Writes immediately, for scenePhase .background where the debounce would
    /// never fire.
    func flushMetadataCache() {
        persistTask?.cancel()
        persistTask = Task { await writeMetadataCache() }
    }

    private func writeMetadataCache() async {
        let snapshot = persistableMetadata()
        await Task.detached { [metadataCacheRepository] in
            metadataCacheRepository.save(snapshot)
        }.value
    }

    /// Only listed notes are persisted, which prunes deleted notes and notes
    /// opened in place from the Files app.
    private func persistableMetadata() -> [String: NoteMetadata] {
        let listed = Set((inboxIndex + archivedIndex).map(\.fileName))
        return metadataByFileName.filter { listed.contains($0.key) }
    }
}
