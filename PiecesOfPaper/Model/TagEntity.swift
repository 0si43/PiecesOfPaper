import Foundation
import SwiftUI

// Equality is memberwise: an id-only == told SwiftUI that a renamed tag was
// unchanged, so edits never reached the screen. Callers that mean "the same tag,
// whatever it is called now" compare .id explicitly.
struct TagEntity: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var color: CodableUIColor
}

struct CodableUIColor: Codable, Equatable {
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0

    var swiftUIColor: Color {
        .init(red: red, green: green, blue: blue, opacity: 0.7)
    }

    // The 0.7 above is how a tag capsule is drawn, not what the user picked:
    // seeding a ColorPicker with swiftUIColor would show a faded swatch and
    // write that fade back into the stored alpha
    var opaqueColor: Color {
        .init(red: red, green: green, blue: blue)
    }

    init(uiColor: UIColor) {
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    }
}
