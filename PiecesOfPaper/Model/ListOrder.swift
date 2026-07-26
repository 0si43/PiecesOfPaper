import Foundation

struct ListOrder: Codable {
    // The raw values are persisted, so the display text lives in `label` instead:
    // retyping a raw value would reset every stored sort setting to the default
    enum SortBy: String, CaseIterable, Identifiable, Codable {
        case createdDate = "created date"
        case updatedDate = "updated date"

        var id: String { self.rawValue }

        var label: String {
            switch self {
            case .createdDate: "Created Date"
            case .updatedDate: "Updated Date"
            }
        }
    }
    var sortBy: SortBy = .updatedDate

    enum SortOrder: String, CaseIterable, Identifiable, Codable {
        case ascending, descending

        var id: String { self.rawValue }

        var label: String {
            switch self {
            case .ascending: "Ascending"
            case .descending: "Descending"
            }
        }
    }
    var sortOrder: SortOrder = .descending

    var filterBy = [TagEntity]()
}
