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
        let contentSize = hasContent ? bounds.size : CGSize(width: 1_024, height: 768)
        // The trait collection carries no display scale in the extension
        // context; every device on this deployment target is at least 2x.
        let displayScale = max(UITraitCollection.current.displayScale, 2)
        // Cap the total pixel count, not the longest side: device verification
        // showed renders around 3.4M pixels get jetsammed in this extension
        // while ~1M-pixel renders survive. Screen-sized drawings hit full
        // display scale under a dimension cap and were exactly the ones dying.
        let maxPixelCount: CGFloat = 2_000_000
        let areaCap = (maxPixelCount / (contentSize.width * contentSize.height)).squareRoot()
        let pixelRatio = min(displayScale, areaCap)
        let pixelSize = CGSize(width: contentSize.width * pixelRatio,
                               height: contentSize.height * pixelRatio)

        return QLPreviewReply(dataOfContentType: .png, contentSize: contentSize) { _ in
            // Off-main PKDrawing.image is safe here: the extension is a separate
            // process with no PKCanvasView, so the app-side constraint from #187
            // does not apply.
            var rendered = UIImage()
            // The pool releases the intermediate PKDrawing bitmap before PNG
            // encoding, which allocates its own buffer on top.
            autoreleasepool {
                var image = UIImage()
                if hasContent {
                    // Fixed light style so ink drawn in dark mode stays visible on white.
                    UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
                        image = drawing.image(from: bounds, scale: pixelRatio)
                    }
                }
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                rendered = UIGraphicsImageRenderer(size: pixelSize, format: format).image { context in
                    UIColor.white.setFill()
                    context.fill(CGRect(origin: .zero, size: pixelSize))
                    if hasContent {
                        image.draw(in: CGRect(origin: .zero, size: pixelSize))
                    }
                }
            }
            guard let pngData = rendered.pngData() else {
                throw CocoaError(.fileWriteUnknown)
            }
            return pngData
        }
    }
}
