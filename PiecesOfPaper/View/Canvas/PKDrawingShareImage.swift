import PencilKit
import UIKit

extension PKDrawing {
    /// Renders the drawing under an explicit interface style. PencilKit adapts
    /// ink colors to the current trait, and outside a view update
    /// UITraitCollection.current tracks neither the window nor its appearance
    /// override, so callers state the style they want.
    /// @MainActor because off-main PKDrawing.image breaks stroke rendering
    /// process-wide on device (#187, docs/GOTCHAS.md)
    @MainActor
    func image(scale: CGFloat, style: UIUserInterfaceStyle) -> UIImage {
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: style)
        trait.performAsCurrent {
            image = self.image(from: bounds, scale: scale)
        }
        return image
    }

    /// Renders the drawing with light-mode colors for the share sheet, matching
    /// what the QuickLook and Thumbnail extensions produce.
    @MainActor
    func lightModeImage(scale: CGFloat) -> UIImage {
        image(scale: scale, style: .light)
    }
}
