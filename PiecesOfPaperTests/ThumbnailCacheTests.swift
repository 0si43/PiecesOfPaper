import Testing
import UIKit
@testable import Pieces_of_Paper

struct ThumbnailCacheTests {
    private let entry = NoteIndexEntry(fileURL: URL(fileURLWithPath: "/notes/2024-01-02-03-04-051234.pop"),
                                       creationDate: nil,
                                       contentModificationDate: Date(timeIntervalSince1970: 2_000))

    // PencilKit adapts ink to the interface style, so a thumbnail rendered under
    // one appearance must not be served under the other
    @Test func test_key_differsByInterfaceStyle() {
        #expect(ThumbnailCache.key(for: entry, style: .light) != ThumbnailCache.key(for: entry, style: .dark))
    }

    @Test func test_key_differsWhenTheNoteIsEdited() {
        let edited = NoteIndexEntry(fileURL: entry.fileURL,
                                    createdDate: entry.createdDate,
                                    updatedDate: entry.updatedDate.addingTimeInterval(1))
        #expect(ThumbnailCache.key(for: entry, style: .light) != ThumbnailCache.key(for: edited, style: .light))
    }
}
