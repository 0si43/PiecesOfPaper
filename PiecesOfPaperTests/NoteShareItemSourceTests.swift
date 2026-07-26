import Testing
import Foundation
@testable import Pieces_of_Paper

struct NoteShareItemSourceTests {
    private let locale = Locale(identifier: "en_US")

    // The share sheet header is built from this, so it must name the note rather
    // than describe the file type
    @Test func test_title_namesTheNoteWithItsDate() {
        let updatedDate = Date(timeIntervalSince1970: 1_000_000)
        let title = NoteShareItemSource.title(updatedDate: updatedDate, locale: locale)

        let expectedDate = updatedDate.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale)
        )
        #expect(title == "Note, \(expectedDate)")
    }

    @Test func test_title_distinguishesNotesByDate() {
        let first = NoteShareItemSource.title(updatedDate: Date(timeIntervalSince1970: 1_000_000), locale: locale)
        let second = NoteShareItemSource.title(updatedDate: Date(timeIntervalSince1970: 2_000_000), locale: locale)
        #expect(first != second)
    }
}
