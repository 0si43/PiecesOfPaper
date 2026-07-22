import Foundation
import Testing
import PencilKit
@testable import Pieces_of_Paper

@MainActor
struct NoteDocumentTests {
    private func makeDocument(drawing: PKDrawing = PKDrawing()) -> NoteDocument {
        guard let url = URL(string: "file:///test") else {
            fatalError()
        }

        return NoteDocument(fileURL: url, entity: NoteEntity(drawing: drawing))
    }

    @Test func contents_encodesEntity() throws {
        let document = makeDocument()
        let data = try #require(try document.contents(forType: "") as? Data)
        let decoded = try PropertyListDecoder().decode(NoteEntity.self, from: data)
        #expect(decoded.id == document.entity.id)
    }

    @Test func load_roundTripsEntity() throws {
        let document = makeDocument()
        let data = try #require(try document.contents(forType: "") as? Data)
        let other = makeDocument()
        try other.load(fromContents: data, ofType: nil)
        #expect(other.entity.id == document.entity.id)
    }

    @Test func load_roundTripsNonEmptyDrawing() throws {
        let document = makeDocument(drawing: .stub())
        let data = try #require(try document.contents(forType: "") as? Data)
        let other = makeDocument()
        try other.load(fromContents: data, ofType: nil)
        #expect(!other.entity.drawing.strokes.isEmpty)
        #expect(other.entity.drawing == document.entity.drawing)
    }

    @Test func load_throwsOnGarbageData() {
        let document = makeDocument()
        let originalId = document.entity.id
        #expect(throws: (any Error).self) {
            try document.load(fromContents: Data("not a plist".utf8), ofType: nil)
        }
        #expect(document.entity.id == originalId)
    }

    @Test func load_throwsOnNonDataContents() {
        let document = makeDocument()
        #expect(throws: NoteDocumentError.self) {
            try document.load(fromContents: NSObject(), ofType: nil)
        }
    }
}

struct NoteEntityCodingTests {
    // Shape of a note written before tags were normalized to ids
    private struct LegacyNoteEntity: Encodable {
        var id = UUID()
        var drawing = PKDrawing()
        var tags: [TagEntity]
        var createdDate = Date(timeIntervalSince1970: 1_000)
        var updatedDate = Date(timeIntervalSince1970: 2_000)
    }

    // Shape of a note whose tag key is absent altogether
    private struct UntaggedNoteEntity: Encodable {
        var id = UUID()
        var drawing = PKDrawing()
        var createdDate = Date(timeIntervalSince1970: 1_000)
        var updatedDate = Date(timeIntervalSince1970: 2_000)
    }

    private let tags = [
        TagEntity(name: "idea", color: CodableUIColor(uiColor: .systemYellow)),
        TagEntity(name: "memo", color: CodableUIColor(uiColor: .systemBlue))
    ]

    @Test func currentFormat_roundTripsTagIds() throws {
        var entity = NoteEntity(drawing: PKDrawing())
        entity.tagIds = tags.map(\.id)
        let data = try PropertyListEncoder().encode(entity)
        let decoded = try PropertyListDecoder().decode(NoteEntity.self, from: data)
        #expect(decoded.tagIds == tags.map(\.id))
        #expect(decoded.legacyTags.isEmpty)
        #expect(decoded == entity)
    }

    @Test func legacyFormat_decodesEmbeddedTagsAsIdsAndKeepsCopies() throws {
        let legacy = LegacyNoteEntity(tags: tags)
        let data = try PropertyListEncoder().encode(legacy)
        let decoded = try PropertyListDecoder().decode(NoteEntity.self, from: data)
        #expect(decoded.id == legacy.id)
        #expect(decoded.tagIds == tags.map(\.id))
        #expect(decoded.legacyTags.map(\.name) == ["idea", "memo"])
    }

    @Test func legacyFormat_reEncodesWithoutEmbeddedCopies() throws {
        let legacyData = try PropertyListEncoder().encode(LegacyNoteEntity(tags: tags))
        let decoded = try PropertyListDecoder().decode(NoteEntity.self, from: legacyData)
        let reEncoded = try PropertyListEncoder().encode(decoded)
        let plist = try PropertyListSerialization.propertyList(from: reEncoded, format: nil)
        let dictionary = try #require(plist as? [String: Any])
        #expect(dictionary["tags"] == nil)
        #expect(dictionary["tagIds"] as? [String] == tags.map(\.id.uuidString))
    }

    @Test func missingTagKey_decodesAsUntagged() throws {
        let data = try PropertyListEncoder().encode(UntaggedNoteEntity())
        let decoded = try PropertyListDecoder().decode(NoteEntity.self, from: data)
        #expect(decoded.tagIds.isEmpty)
        #expect(decoded.legacyTags.isEmpty)
    }

    @Test func legacyTags_areNotPartOfEquality() throws {
        var entity = NoteEntity(drawing: PKDrawing())
        var withLegacyCopies = entity
        withLegacyCopies.legacyTags = tags
        entity.tagIds = tags.map(\.id)
        withLegacyCopies.tagIds = tags.map(\.id)
        #expect(entity == withLegacyCopies)
    }
}

struct NoteConflictResolverTests {
    private let base = Date(timeIntervalSinceReferenceDate: 1_000)

    @Test func currentNewest_returnsNil() {
        let index = NoteConflictResolver.newestVersionIndex(
            currentModificationDate: base,
            conflictModificationDates: [base.addingTimeInterval(-10), base.addingTimeInterval(-20)]
        )
        #expect(index == nil)
    }

    @Test func conflictNewest_returnsItsIndex() {
        let index = NoteConflictResolver.newestVersionIndex(
            currentModificationDate: base,
            conflictModificationDates: [base.addingTimeInterval(-10), base.addingTimeInterval(10)]
        )
        #expect(index == 1)
    }

    @Test func newestAmongMultipleConflicts_wins() {
        let index = NoteConflictResolver.newestVersionIndex(
            currentModificationDate: base,
            conflictModificationDates: [
                base.addingTimeInterval(30),
                base.addingTimeInterval(50),
                base.addingTimeInterval(40)
            ]
        )
        #expect(index == 1)
    }

    @Test func tieWithCurrent_favorsCurrent() {
        let index = NoteConflictResolver.newestVersionIndex(
            currentModificationDate: base,
            conflictModificationDates: [base]
        )
        #expect(index == nil)
    }

    @Test func nilCurrentDate_losesToDatedConflict() {
        let index = NoteConflictResolver.newestVersionIndex(
            currentModificationDate: nil,
            conflictModificationDates: [base]
        )
        #expect(index == 0)
    }

    @Test func nilConflictDates_loseToDatedCurrent() {
        let index = NoteConflictResolver.newestVersionIndex(
            currentModificationDate: base,
            conflictModificationDates: [nil, nil]
        )
        #expect(index == nil)
    }

    @Test func emptyConflictList_returnsNil() {
        let index = NoteConflictResolver.newestVersionIndex(
            currentModificationDate: base,
            conflictModificationDates: []
        )
        #expect(index == nil)
    }
}
