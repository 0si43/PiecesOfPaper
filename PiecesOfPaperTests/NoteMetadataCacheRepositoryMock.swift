import Foundation
@testable import Pieces_of_Paper

/// Stands in for the on-disk cache file: save() replaces what load() returns,
/// so a store can be started "warm" by seeding entries.
final class NoteMetadataCacheRepositoryMock: NoteMetadataCacheRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: NoteMetadata]
    private var saves = 0

    init(entries: [String: NoteMetadata] = [:]) {
        storage = entries
    }

    var savedEntries: [String: NoteMetadata] { lock.withLock { storage } }
    var saveCount: Int { lock.withLock { saves } }

    func load() -> [String: NoteMetadata] { lock.withLock { storage } }

    func save(_ entries: [String: NoteMetadata]) {
        lock.withLock {
            storage = entries
            saves += 1
        }
    }
}
