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

    /// Renders the drawing with light-mode colors on an opaque white background for
    /// the share sheet, matching what the QuickLook and Thumbnail extensions produce.
    /// The fill is not decoration: PKDrawing.image leaves the background transparent,
    /// and a viewer in dark mode composites that on black, hiding the dark ink the
    /// light trait is there to preserve.
    @MainActor
    func lightModeImage(scale: CGFloat) -> UIImage {
        let ink = image(scale: scale, style: .light)
        guard ink.size.width > 0, ink.size.height > 0 else { return ink }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: ink.size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: ink.size))
            ink.draw(at: .zero)
        }
    }
}
