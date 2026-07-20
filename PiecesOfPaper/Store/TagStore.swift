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

    init(repository: TagRepositoryProtocol = TagRepository()) {
        self.repository = repository
        self.tags = repository.fetchAll()
        if FilePath.isiCloudActive {
            cloudMonitor = TagListCloudMonitor()
            cloudMonitor?.onUpdate = { [weak self] in self?.reload() }
        }
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
        if !repository.saveAll(tags) {
            reload()
        }
    }

    func tagsFor(note: NoteData) -> [TagEntity] {
        tags.filter { note.entity.tags.contains($0) }
    }

    func tagsNotFor(note: NoteData) -> [TagEntity] {
        tags.filter { !note.entity.tags.contains($0) }
    }

    func filteringTags(from filterBy: [TagEntity]) -> [TagEntity] {
        tags.filter { filterBy.contains($0) }
    }

    func nonFilteringTags(from filterBy: [TagEntity]) -> [TagEntity] {
        tags.filter { !filterBy.contains($0) }
    }

    func reload() {
        tags = repository.fetchAll()
    }
}
