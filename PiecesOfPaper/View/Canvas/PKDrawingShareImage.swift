import PencilKit
import UIKit

extension PKDrawing {
    /// Renders the drawing with light-mode colors for the share sheet.
    /// @MainActor because off-main PKDrawing.image breaks stroke rendering
    /// process-wide on device (#187, docs/GOTCHAS.md)
    @MainActor
    func lightModeImage(scale: CGFloat) -> UIImage {
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        trait.performAsCurrent {
            image = self.image(from: bounds, scale: scale)
        }
        return image
    }
}
