import Foundation

struct ListOrder: Codable {
    enum SortBy: String, CaseIterable, Identifiable, Codable {
        case createdDate = "created date"
        case updatedDate = "updated date"

        var id: String { self.rawValue }
    }
    var sortBy: SortBy = .updatedDate

    enum SortOrder: String, CaseIterable, Identifiable, Codable {
        case ascending, descending

        var id: String { self.rawValue }
    }
    var sortOrder: SortOrder = .descending

    var filterBy = [TagEntity]()
}
