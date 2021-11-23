//
//  UIActivityViewControllerWrapper.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/30.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import SwiftUI

struct UIActivityViewControllerWrapper: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<UIActivityViewControllerWrapper>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<UIActivityViewControllerWrapper>) {}
}
