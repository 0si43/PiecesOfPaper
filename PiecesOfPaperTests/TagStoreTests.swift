//
//  TagStoreTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2026/07/18.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import Testing
@testable import Pieces_of_Paper

@MainActor
struct TagStoreTests {
    let initialTags = [
        TagEntity(name: "idea", color: CodableUIColor(uiColor: .systemYellow)),
        TagEntity(name: "memo", color: CodableUIColor(uiColor: .systemBlue))
    ]
    let repositoryMock: TagRepositoryMock
    let tagStore: TagStore

    init() {
        repositoryMock = TagRepositoryMock(tags: initialTags)
        tagStore = TagStore(repository: repositoryMock)
    }

    @Test func test_init_loadsTagsFromRepository() {
        #expect(tagStore.tags == initialTags)
    }

    @Test func test_add_appendsAndPersists() {
        let tag = TagEntity(name: "new", color: CodableUIColor(uiColor: .systemRed))
        tagStore.add(tag)
        #expect(tagStore.tags == initialTags + [tag])
        #expect(repositoryMock.saveAllCalls.last == initialTags + [tag])
    }

    @Test func test_add_rollsBackWhenSaveFails() {
        repositoryMock.saveShouldSucceed = false
        let tag = TagEntity(name: "new", color: CodableUIColor(uiColor: .systemRed))
        tagStore.add(tag)
        #expect(tagStore.tags == initialTags)
    }

    @Test func test_remove_removesAndPersists() {
        tagStore.remove(initialTags[0])
        #expect(tagStore.tags == [initialTags[1]])
        #expect(repositoryMock.saveAllCalls.last == [initialTags[1]])
    }

    @Test func test_removeAtOffsets_removesAndPersists() {
        tagStore.remove(at: IndexSet(integer: 1))
        #expect(tagStore.tags == [initialTags[0]])
        #expect(repositoryMock.saveAllCalls.last == [initialTags[0]])
    }

    @Test func test_remove_rollsBackWhenSaveFails() {
        repositoryMock.saveShouldSucceed = false
        tagStore.remove(initialTags[0])
        #expect(tagStore.tags == initialTags)
    }

    @Test func test_restoreIfEmpty_ignoresSalvagedTagsWhileTagListIsNotEmpty() {
        let salvaged = TagEntity(name: "salvaged", color: CodableUIColor(uiColor: .systemPink))
        tagStore.restoreIfEmpty([salvaged])
        #expect(tagStore.tags == initialTags)
        #expect(repositoryMock.saveAllCalls.isEmpty)
    }
}

@MainActor
struct TagStoreRestoreTests {
    let repositoryMock = TagRepositoryMock(tags: [])
    let tagStore: TagStore
    let salvaged = [
        TagEntity(name: "salvaged", color: CodableUIColor(uiColor: .systemPink)),
        TagEntity(name: "another", color: CodableUIColor(uiColor: .systemTeal))
    ]

    init() {
        tagStore = TagStore(repository: repositoryMock)
    }

    @Test func test_restoreIfEmpty_addsAndPersistsSalvagedTags() {
        tagStore.restoreIfEmpty(salvaged)
        #expect(tagStore.tags == salvaged)
        #expect(repositoryMock.saveAllCalls.last == salvaged)
    }

    @Test func test_restoreIfEmpty_dropsDuplicateIds() {
        tagStore.restoreIfEmpty([salvaged[0], salvaged[0], salvaged[1]])
        #expect(tagStore.tags == salvaged)
    }

    @Test func test_restoreIfEmpty_rollsBackWhenSaveFails() {
        repositoryMock.saveShouldSucceed = false
        tagStore.restoreIfEmpty(salvaged)
        #expect(tagStore.tags.isEmpty)
    }
}

final class TagRepositoryMock: TagRepositoryProtocol {
    var storedTags: [TagEntity]
    var saveShouldSucceed = true
    private(set) var saveAllCalls: [[TagEntity]] = []

    init(tags: [TagEntity]) {
        storedTags = tags
    }

    func fetchAll() -> [TagEntity] {
        storedTags
    }

    @discardableResult
    func saveAll(_ tags: [TagEntity]) -> Bool {
        saveAllCalls.append(tags)
        guard saveShouldSucceed else { return false }
        storedTags = tags
        return true
    }
}
