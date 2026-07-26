import Testing
@testable import Pieces_of_Paper

struct ReleaseNoteTests {
    // `latest` is what the unread badge compares against, so an empty list would
    // silently mean "nothing is ever new"
    @Test func test_latest_isPresent() {
        #expect(ReleaseNote.latest != nil)
    }

    @Test func test_all_isOrderedNewestFirst() {
        let versions = ReleaseNote.all.map(\.version)
        let sorted = versions.sorted { $0.compare($1, options: .numeric) == .orderedDescending }
        #expect(versions == sorted)
    }

    // The version doubles as the identity and as the seen-marker persisted in
    // PreferenceStore, so a duplicate would make the unread badge unresolvable
    @Test func test_versions_areUnique() {
        #expect(Set(ReleaseNote.all.map(\.version)).count == ReleaseNote.all.count)
    }

    @Test func test_everyEntry_hasHighlights() {
        for note in ReleaseNote.all {
            #expect(!note.highlights.isEmpty)
        }
    }

    @Test func test_dates_areRealCalendarDates() {
        for note in ReleaseNote.all {
            #expect(note.date != .distantPast)
        }
    }
}
