import SwiftUI

/// One release's highlights, rendered as a section of the What's New page.
struct ReleaseNote: Identifiable {
    let version: String
    let date: Date
    let highlights: [LocalizedStringKey]

    var id: String { version }
}

extension ReleaseNote {
    static var latest: ReleaseNote? { all.first }

    /// Newest first — the page renders this order, and `latest` drives the unread badge.
    static let all: [ReleaseNote] = [
        ReleaseNote(
            version: "4.0.0",
            date: date(year: 2026, month: 7, day: 27),
            highlights: [
                """
                Your notes are files now. They show up in the Files app as drawing thumbnails, \
                preview with the space bar, and open straight into Pieces of Paper to edit in place
                """,
                """
                The canvas controls moved into a floating panel, tapping the paper hides them for \
                a plain sheet, the share sheet opens from the panel, and Settings has a Light/Dark \
                appearance option
                """,
                "Tags can be renamed and edited",
                "The note list loads faster",
                "Requires iPadOS 18",
                """
                Update Pieces of Paper on every device you use. A device still running 3.3.0 shows \
                an empty note list until it is updated, and its notes come back once it is
                """
            ]
        )
    ]

    // The calendar's time zone is the device's, so the day this produces is the day the
    // page formats back out — fixing it to GMT would show the previous date west of it
    private static func date(year: Int, month: Int, day: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }
}
