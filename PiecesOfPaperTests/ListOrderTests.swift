import Testing
@testable import Pieces_of_Paper

struct ListOrderTests {
    // The raw values are the UserDefaults payload: retyping one silently resets
    // every stored sort setting, which is why the display text lives in `label`
    @Test func test_rawValues_areStable() {
        #expect(ListOrder.SortBy.createdDate.rawValue == "created date")
        #expect(ListOrder.SortBy.updatedDate.rawValue == "updated date")
        #expect(ListOrder.SortOrder.ascending.rawValue == "ascending")
        #expect(ListOrder.SortOrder.descending.rawValue == "descending")
    }

    @Test func test_labels_areTitleCased() {
        #expect(ListOrder.SortBy.createdDate.label == "Created Date")
        #expect(ListOrder.SortBy.updatedDate.label == "Updated Date")
        #expect(ListOrder.SortOrder.ascending.label == "Ascending")
        #expect(ListOrder.SortOrder.descending.label == "Descending")
    }
}
