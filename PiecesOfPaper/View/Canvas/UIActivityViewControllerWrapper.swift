import UIKit
import SwiftUI

struct UIActivityViewControllerWrapper: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities = [UIActivity]()

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
