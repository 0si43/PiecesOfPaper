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

    init(repository: TagRepositoryProtocol = TagRepository()) {
        self.repository = repository
        self.tags = repository.fetchAll()
    }

    func add(_ tag: TagEntity) {
        tags.append(tag)
        repository.saveAll(tags)
    }

    func remove(at offsets: IndexSet) {
        tags.remove(atOffsets: offsets)
        repository.saveAll(tags)
    }

    func remove(_ tag: TagEntity) {
        tags.removeAll { $0 == tag }
        repository.saveAll(tags)
    }

    func tagsFor(document: NoteDocument) -> [TagEntity] {
        tags.filter { document.entity.tags.contains($0) }
    }

    func tagsNotFor(document: NoteDocument) -> [TagEntity] {
        tags.filter { !document.entity.tags.contains($0) }
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
