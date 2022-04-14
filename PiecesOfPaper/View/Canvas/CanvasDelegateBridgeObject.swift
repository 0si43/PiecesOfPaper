//
//  CanvasDelegateBridgeObject.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/29.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit
import LinkPresentation

protocol CanvasDelegateBridgeObjectDelegate: AnyObject {
    var hideExceptPaper: Bool { get set }
    var canvasView: PKCanvasView { get }
    func save(drawing: PKDrawing)
}

// MARK: - PKToolPickerObserver
///  This class conform some protocol, because SwiftUI Views cannot conform PencilKit delegates
final class CanvasDelegateBridgeObject: NSObject, PKToolPickerObserver {
    weak var delegate: CanvasDelegateBridgeObjectDelegate?

    override init() {
        super.init()
    }
}

// MARK: - UIActivityItemSource
extension CanvasDelegateBridgeObject: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        ""
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        nil
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Share your note"
        return metadata
    }
}

// MARK: - UIScrollViewDelegate
extension CanvasDelegateBridgeObject: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        delegate?.canvasView
    }
}
