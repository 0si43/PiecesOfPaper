import SwiftUI

extension Color {
    /// Background for a highlighted callout block.
    /// Defined in code rather than Assets.xcassets, which holds no color sets:
    /// the same 15% yellow that reads as a highlight on white all but vanishes
    /// on black, so Dark gets a stronger tint instead of the same value.
    static let calloutBackground = Color(UIColor { traits in
        let alpha: CGFloat = traits.userInterfaceStyle == .dark ? 0.28 : 0.15
        return UIColor.systemYellow.resolvedColor(with: traits).withAlphaComponent(alpha)
    })
}
