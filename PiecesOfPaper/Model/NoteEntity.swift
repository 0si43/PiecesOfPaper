import Foundation
import PencilKit

struct NoteEntity: Codable, Equatable {
    var id = UUID()
    var drawing: PKDrawing
    var tags: [TagEntity]
    var createdDate: Date
    var updatedDate: Date

    init(drawing: PKDrawing,
         tags: [TagEntity] = [],
         createdDate: Date = Date(),
         updatedDate: Date = Date()) {
        self.drawing = drawing
        self.tags = tags
        self.createdDate = createdDate
        self.updatedDate = updatedDate
    }
}
