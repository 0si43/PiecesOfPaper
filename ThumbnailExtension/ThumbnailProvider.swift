//
//  ThumbnailProvider.swift
//  ThumbnailExtension
//
//  Created by Nakajima on 2026/07/19.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import QuickLookThumbnailing
import PencilKit

final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest,
                                   _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let entity: NoteEntity
        do {
            let data = try Data(contentsOf: request.fileURL)
            entity = try PropertyListDecoder().decode(NoteEntity.self, from: data)
        } catch {
            handler(nil, error)
            return
        }

        let drawing = entity.drawing
        let bounds = drawing.bounds
        let maximumSize = request.maximumSize

        guard !bounds.isNull, bounds.width > 0, bounds.height > 0 else {
            handler(QLThumbnailReply(contextSize: maximumSize) {
                UIColor.white.setFill()
                UIRectFill(CGRect(origin: .zero, size: maximumSize))
                return true
            }, nil)
            return
        }

        let ratio = min(maximumSize.width / bounds.width, maximumSize.height / bounds.height)
        let drawSize = CGSize(width: bounds.width * ratio, height: bounds.height * ratio)
        let contextSize = CGSize(width: max(drawSize.width, request.minimumSize.width),
                                 height: max(drawSize.height, request.minimumSize.height))

        handler(QLThumbnailReply(contextSize: contextSize) {
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: contextSize))
            // Off-main PKDrawing.image is safe here: the extension is a separate
            // process with no PKCanvasView, so the app-side constraint from #187
            // does not apply.
            var image = UIImage()
            // Fixed light style so ink drawn in dark mode stays visible on white.
            UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
                // Render at thumbnail resolution, not native drawing size, to
                // stay under the extension memory limit.
                image = drawing.image(from: bounds, scale: ratio * request.scale)
            }
            let origin = CGPoint(x: (contextSize.width - drawSize.width) / 2,
                                 y: (contextSize.height - drawSize.height) / 2)
            image.draw(in: CGRect(origin: origin, size: drawSize))
            return true
        }, nil)
    }
}
