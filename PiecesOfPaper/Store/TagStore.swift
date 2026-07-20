//
//  TagStore.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

@Observable
@MainActor
final class TagStore {
    private(set) var tags: [TagEntity]
    private let repository: TagRepositoryProtocol
    @ObservationIgnored private var cloudMonitor: TagListCloudMonitor?
    @ObservationIgnored private var fileOperationTask: Task<Void, Never>?

    init(repository: TagRepositoryProtocol = TagRepository()) {
        self.repository = repository
        // Starts empty because the coordinated read cannot run before init
        // returns; the same transient empty list already occurs when the
        // iCloud copy is still downloading (#199).
        self.tags = []
        if FilePath.isiCloudActive {
            cloudMonitor = TagListCloudMonitor()
            cloudMonitor?.onUpdate = { [weak self] in self?.reload() }
        }
        reload()
    }

    func add(_ tag: TagEntity) {
        tags.append(tag)
        saveOrRollback()
    }

    func remove(at offsets: IndexSet) {
        tags.remove(atOffsets: offsets)
        saveOrRollback()
    }

    func remove(_ tag: TagEntity) {
        tags.removeAll { $0 == tag }
        saveOrRollback()
    }

    // Reload from disk when a save fails so the UI never shows a state that was not persisted
    private func saveOrRollback() {
        let tags = tags
        enqueueFileOperation {
            if await self.repository.saveAll(tags) { return }
            self.tags = await self.repository.fetchAll()
        }
    }

    /// Serializes reads and writes: the cloud monitor reloads on every metadata
    /// update, and an out-of-order read would overwrite a newer edit.
    private func enqueueFileOperation(_ operation: @escaping () async -> Void) {
        let previous = fileOperationTask
        fileOperationTask = Task {
            await previous?.value
            await operation()
        }
    }

    func tagsMatching(_ noteTags: [TagEntity]) -> [TagEntity] {
        tags.filter { noteTags.contains($0) }
    }

    func tagsNotMatching(_ noteTags: [TagEntity]) -> [TagEntity] {
        tags.filter { !noteTags.contains($0) }
    }

    func filteringTags(from filterBy: [TagEntity]) -> [TagEntity] {
        tags.filter { filterBy.contains($0) }
    }

    func nonFilteringTags(from filterBy: [TagEntity]) -> [TagEntity] {
        tags.filter { !filterBy.contains($0) }
    }

    func reload() {
        enqueueFileOperation {
            self.tags = await self.repository.fetchAll()
        }
    }
}
