import UIKit
import PencilKit

/// Renders note thumbnails asynchronously and caches them.
/// The key is derivable from a NoteIndexEntry alone, so a cache hit needs no
/// document open; it includes updatedDate, so an edited note re-renders, and
/// uses the file name (stable across archive/unarchive moves) instead of the
/// entity id, which is unknown before the document is opened.
final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSString, UIImage>()

    static func key(for entry: NoteIndexEntry) -> String {
        "\(entry.fileURL.lastPathComponent)-\(entry.updatedDate.timeIntervalSince1970)"
    }

    func cached(key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func thumbnail(for drawing: PKDrawing, key: String) async -> UIImage {
        if let cached = cached(key: key) {
            return cached
        }
        guard !drawing.bounds.isNull else { return UIImage() }

        // Not Task.detached: rendering PKDrawing off the main thread breaks
        // PKCanvasView drawing process-wide on device (#187).
        let image = await MainActor.run {
            drawing.image(from: drawing.bounds, scale: 1.0)
        }
        cache.setObject(image, forKey: key as NSString)
        return image
    }
}
