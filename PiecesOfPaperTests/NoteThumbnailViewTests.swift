import Testing
import Foundation
@testable import Pieces_of_Paper

struct NoteThumbnailViewTests {
    private let locale = Locale(identifier: "en_US")

    @Test func accessibilityLabelWithoutTagsContainsFormattedDate() {
        let updatedDate = Date(timeIntervalSince1970: 1_000_000)
        let label = NoteThumbnailView.accessibilityLabel(updatedDate: updatedDate, tagNames: [], locale: locale)

        let expectedDate = updatedDate.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale)
        )
        #expect(label == "Note, \(expectedDate)")
        #expect(!label.contains("tags:"))
    }

    @Test func accessibilityLabelWithTagsAppendsTagNames() {
        let label = NoteThumbnailView.accessibilityLabel(updatedDate: Date(timeIntervalSince1970: 1_000_000),
                                                         tagNames: ["idea", "memo"],
                                                         locale: locale)
        #expect(label.hasPrefix("Note, "))
        #expect(label.hasSuffix(", tags: idea, memo"))
    }

    @Test func accessibilityLabelDistinguishesNotesByDate() {
        let first = NoteThumbnailView.accessibilityLabel(updatedDate: Date(timeIntervalSince1970: 1_000_000),
                                                         tagNames: [],
                                                         locale: locale)
        let second = NoteThumbnailView.accessibilityLabel(updatedDate: Date(timeIntervalSince1970: 2_000_000),
                                                          tagNames: [],
                                                          locale: locale)
        #expect(first != second)
    }
}
