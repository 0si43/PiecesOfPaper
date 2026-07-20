//
//  NoteStore+Loading.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2026/07/20.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

// MARK: - Load-on-demand accessors

extension NoteStore {
    /// Tags for a list row; empty until the row's document has been opened.
    func tags(for entry: NoteIndexEntry) -> [TagEntity] {
        validMetadata(for: entry)?.tags ?? []
    }

    func requestShare(_ entry: NoteIndexEntry) {
        Task {
            if let note = await loadNote(entry) {
                noteToShare = note
            } else {
                presentOpenFailedAlert()
            }
        }
    }

    func requestTag(_ entry: NoteIndexEntry) {
        Task {
            if let note = await loadNote(entry) {
                noteToTag = note
            } else {
                presentOpenFailedAlert()
            }
        }
    }

    func presentOpenFailedAlert() {
        alertType = .error(NoteStoreError.openFailed(count: 1))
        showAlert = true
    }
}

// MARK: - Tag-filter hydration

extension NoteStore {
    func isFilterHydrating(for directory: NoteDirectory) -> Bool {
        hydratingDirectories.contains(directory)
    }

    /// Tags live inside each document, so an active tag filter can only match
    /// notes whose metadata is loaded. Opens every entry lacking valid
    /// metadata in the background — discarding the drawings — so the filtered
    /// list fills in progressively.
    func ensureMetadataForFilter(directory: NoteDirectory) {
        hydrationTasks[directory]?.cancel()
        hydrationTasks[directory] = nil
        hydratingDirectories.remove(directory)
        guard !listOrder(for: directory).filterBy.isEmpty else { return }
        let index = directory == .inbox ? inboxIndex : archivedIndex
        let pending = index.filter { validMetadata(for: $0) == nil }
        guard !pending.isEmpty else { return }

        hydratingDirectories.insert(directory)
        hydrationTasks[directory] = Task {
            await withTaskGroup(of: Void.self) { group in
                var iterator = pending.makeIterator()
                // Width-limited so only a few drawings are decoded at a time
                for _ in 0..<4 {
                    guard let entry = iterator.next() else { break }
                    group.addTask { _ = await self.loadNote(entry) }
                }
                for await _ in group {
                    guard !Task.isCancelled, let entry = iterator.next() else { continue }
                    group.addTask { _ = await self.loadNote(entry) }
                }
            }
            // A cancelled run leaves the state to the ensure call that
            // cancelled it
            if !Task.isCancelled {
                hydratingDirectories.remove(directory)
                hydrationTasks[directory] = nil
            }
        }
    }
}
