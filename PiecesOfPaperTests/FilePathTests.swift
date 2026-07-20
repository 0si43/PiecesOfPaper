//
//  FilePathTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2026/07/20.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Testing
import Foundation
@testable import Pieces_of_Paper

struct FilePathTests {
    // A freshly generated file name parses back to (approximately) now
    @Test func parseTimestamp_roundTripsGeneratedFileName() {
        let name = FilePath.fileName
        let parsed = FilePath.parseTimestamp(fromFileName: name)
        #expect(parsed != nil)
        if let parsed {
            #expect(abs(parsed.timeIntervalSinceNow) < 5)
        }
    }

    // A known timestamp maps to the expected calendar components
    @Test func parseTimestamp_parsesKnownTimestamp() throws {
        let parsed = try #require(FilePath.parseTimestamp(fromFileName: "2024-01-02-03-04-051234.pop"))
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: parsed
        )
        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 2)
        #expect(components.hour == 3)
        #expect(components.minute == 4)
        #expect(components.second == 5)
    }

    // Legacy .plist names share the same timestamp stem
    @Test func parseTimestamp_parsesLegacyPlistName() {
        #expect(FilePath.parseTimestamp(fromFileName: "2021-11-23-09-15-301234.plist") != nil)
    }

    // Non-timestamp names return nil instead of a garbage date
    @Test func parseTimestamp_returnsNilForNonTimestampName() {
        #expect(FilePath.parseTimestamp(fromFileName: "IMG_1234.pop") == nil)
        #expect(FilePath.parseTimestamp(fromFileName: "note.pop") == nil)
        #expect(FilePath.parseTimestamp(fromFileName: "") == nil)
    }
}
