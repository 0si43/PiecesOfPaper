import Foundation
import PencilKit

struct NoteEntity: Codable, Equatable {
    var id = UUID()
    var drawing: PKDrawing
    var tagIds: [UUID]
    var createdDate: Date
    var updatedDate: Date
    /// Tag copies found in a legacy note, kept in memory so the tag list can be
    /// restored from them. Never encoded, never part of equality.
    var legacyTags: [TagEntity] = []

    private enum CodingKeys: String, CodingKey {
        case id, drawing, tagIds, tags, createdDate, updatedDate
    }

    init(drawing: PKDrawing,
         tagIds: [UUID] = [],
         createdDate: Date = Date(),
         updatedDate: Date = Date()) {
        self.drawing = drawing
        self.tagIds = tagIds
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        drawing = try container.decode(PKDrawing.self, forKey: .drawing)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        updatedDate = try container.decode(Date.self, forKey: .updatedDate)
        if let tagIds = try container.decodeIfPresent([UUID].self, forKey: .tagIds) {
            self.tagIds = tagIds
        } else {
            let tags = try container.decodeIfPresent([TagEntity].self, forKey: .tags) ?? []
            tagIds = tags.map(\.id)
            legacyTags = tags
        }
    }

    // Writes the new key only, so every note migrates on its next save. The
    // legacy key stays readable permanently: devices on older app versions keep
    // writing it into the iCloud container.
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(drawing, forKey: .drawing)
        try container.encode(tagIds, forKey: .tagIds)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(updatedDate, forKey: .updatedDate)
    }

    static func == (lhs: NoteEntity, rhs: NoteEntity) -> Bool {
        lhs.id == rhs.id
            && lhs.drawing == rhs.drawing
            && lhs.tagIds == rhs.tagIds
            && lhs.createdDate == rhs.createdDate
            && lhs.updatedDate == rhs.updatedDate
    }
}
