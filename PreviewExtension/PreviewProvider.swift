//
//  PreviewProvider.swift
//  PreviewExtension
//
//  Created by Nakajima on 2026/07/19.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import QuickLook
import PencilKit
import UniformTypeIdentifiers

// QLPreviewingController conformance is what exposes providePreview(for:) to
// the Quick Look host; without it the extension loads but never renders.
final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let data = try Data(contentsOf: request.fileURL)
        let entity = try PropertyListDecoder().decode(NoteEntity.self, from: data)
        let drawing = entity.drawing
        let bounds = drawing.bounds

        let hasContent = !bounds.isNull && bounds.width > 0 && bounds.height > 0
        // Cap the longest side to bound the bitmap size (extension memory limit).
        let maxDimension: CGFloat = 2_048
        let ratio = hasContent ? min(1.0, maxDimension / max(bounds.width, bounds.height)) : 1.0
        let contextSize = hasContent
            ? CGSize(width: bounds.width * ratio, height: bounds.height * ratio)
            : CGSize(width: 1_024, height: 768)

        return QLPreviewReply(dataOfContentType: .png, contentSize: contextSize) { _ in
            // Off-main PKDrawing.image is safe here: the extension is a separate
            // process with no PKCanvasView, so the app-side constraint from #187
            // does not apply.
            var image = UIImage()
            if hasContent {
                // Fixed light style so ink drawn in dark mode stays visible on white.
                UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
                    image = drawing.image(from: bounds, scale: ratio)
                }
            }
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let rendered = UIGraphicsImageRenderer(size: contextSize, format: format).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: contextSize))
                if hasContent {
                    image.draw(in: CGRect(origin: .zero, size: contextSize))
                }
            }
            guard let pngData = rendered.pngData() else {
                throw CocoaError(.fileWriteUnknown)
            }
            return pngData
        }
    }
}
