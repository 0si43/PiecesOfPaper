//
//  ThumbnailCache.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2026/07/11.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import PencilKit

/// Renders note thumbnails off the main thread and caches them.
/// The cache key includes updatedDate, so an edited note is re-rendered automatically.
final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSString, UIImage>()

    func thumbnail(for note: NoteData) async -> UIImage {
        let key = "\(note.entity.id.uuidString)-\(note.entity.updatedDate.timeIntervalSince1970)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let drawing = note.entity.drawing
        guard !drawing.bounds.isNull else { return UIImage() }

        let image = await Task.detached(priority: .userInitiated) {
            drawing.image(from: drawing.bounds, scale: 1.0)
        }.value
        cache.setObject(image, forKey: key)
        return image
    }
}
