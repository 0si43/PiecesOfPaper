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
