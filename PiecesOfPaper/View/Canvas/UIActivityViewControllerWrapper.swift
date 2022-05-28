//
//  UIActivityViewControllerWrapper.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/30.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import SwiftUI
import LinkPresentation

struct UIActivityViewControllerWrapper: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities = [UIActivity]()

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let items = activityItems + [context.coordinator]
        let controller = UIActivityViewController(activityItems: items,
                                                  applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIActivityItemSource {
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
}
