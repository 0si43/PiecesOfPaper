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

    /// Reads and writes run on the store's internal task chain, so assertions
    /// have to let it drain first.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<100 where !condition() {
            await Task.yield()
        }
    }

    /// The tag list is empty until the load queued by init lands
    private func waitForInitialLoad() async {
        await waitUntil { !tagStore.tags.isEmpty }
    }

    @Test func test_init_loadsTagsFromRepository() async {
        await waitForInitialLoad()
        #expect(tagStore.tags == initialTags)
    }

    @Test func test_add_appendsAndPersists() async {
        await waitForInitialLoad()
        let tag = TagEntity(name: "new", color: CodableUIColor(uiColor: .systemRed))
        tagStore.add(tag)
        await waitUntil { !repositoryMock.saveAllCalls.isEmpty }
        #expect(tagStore.tags == initialTags + [tag])
        #expect(repositoryMock.saveAllCalls.last == initialTags + [tag])
    }

    @Test func test_add_rollsBackWhenSaveFails() async {
        await waitForInitialLoad()
        repositoryMock.saveShouldSucceed = false
        let tag = TagEntity(name: "new", color: CodableUIColor(uiColor: .systemRed))
        tagStore.add(tag)
        await waitUntil { tagStore.tags == initialTags }
        #expect(tagStore.tags == initialTags)
    }

    @Test func test_remove_removesAndPersists() async {
        await waitForInitialLoad()
        tagStore.remove(initialTags[0])
        await waitUntil { !repositoryMock.saveAllCalls.isEmpty }
        #expect(tagStore.tags == [initialTags[1]])
        #expect(repositoryMock.saveAllCalls.last == [initialTags[1]])
    }

    @Test func test_removeAtOffsets_removesAndPersists() async {
        await waitForInitialLoad()
        tagStore.remove(at: IndexSet(integer: 1))
        await waitUntil { !repositoryMock.saveAllCalls.isEmpty }
        #expect(tagStore.tags == [initialTags[0]])
        #expect(repositoryMock.saveAllCalls.last == [initialTags[0]])
    }

    @Test func test_remove_rollsBackWhenSaveFails() async {
        await waitForInitialLoad()
        repositoryMock.saveShouldSucceed = false
        tagStore.remove(initialTags[0])
        await waitUntil { tagStore.tags == initialTags }
        #expect(tagStore.tags == initialTags)
    }

    @Test func test_reload_appliesTheLatestReadWhenCalledRepeatedly() async {
        await waitForInitialLoad()
        let updated = initialTags + [TagEntity(name: "synced", color: CodableUIColor(uiColor: .systemGreen))]

        tagStore.reload()
        repositoryMock.storedTags = updated
        tagStore.reload()
        await waitUntil { tagStore.tags == updated }

        #expect(tagStore.tags == updated)
    }

    @Test func test_restoreIfEmpty_ignoresSalvagedTagsWhileTagListIsNotEmpty() async {
        await waitForInitialLoad()
        let salvaged = TagEntity(name: "salvaged", color: CodableUIColor(uiColor: .systemPink))
        tagStore.restoreIfEmpty([salvaged])
        // Let the enqueued restore drain; it must decline to save
        for _ in 0..<50 { await Task.yield() }
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

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<100 where !condition() {
            await Task.yield()
        }
    }

    init() {
        tagStore = TagStore(repository: repositoryMock)
    }

    @Test func test_restoreIfEmpty_addsAndPersistsSalvagedTags() async {
        tagStore.restoreIfEmpty(salvaged)
        await waitUntil { !repositoryMock.saveAllCalls.isEmpty }
        #expect(tagStore.tags == salvaged)
        #expect(repositoryMock.saveAllCalls.last == salvaged)
    }

    @Test func test_restoreIfEmpty_dropsDuplicateIds() async {
        tagStore.restoreIfEmpty([salvaged[0], salvaged[0], salvaged[1]])
        await waitUntil { tagStore.tags == salvaged }
        #expect(tagStore.tags == salvaged)
    }

    @Test func test_restoreIfEmpty_rollsBackWhenSaveFails() async {
        repositoryMock.saveShouldSucceed = false
        tagStore.restoreIfEmpty(salvaged)
        await waitUntil { repositoryMock.saveAllCalls.contains { !$0.isEmpty } }
        #expect(tagStore.tags.isEmpty)
    }
}

@MainActor
final class TagRepositoryMock: TagRepositoryProtocol {
    var storedTags: [TagEntity]
    var saveShouldSucceed = true
    private(set) var saveAllCalls: [[TagEntity]] = []

    init(tags: [TagEntity]) {
        storedTags = tags
    }

    func fetchAll() async -> [TagEntity] {
        storedTags
    }

    @discardableResult
    func saveAll(_ tags: [TagEntity]) async -> Bool {
        saveAllCalls.append(tags)
        guard saveShouldSucceed else { return false }
        storedTags = tags
        return true
    }
}
