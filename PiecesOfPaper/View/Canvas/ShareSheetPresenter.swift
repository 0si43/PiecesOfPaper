import SwiftUI
import UIKit

/// Puts a `UIActivityViewController` on screen the way UIKit expects: the controller presents
/// itself and picks its own style, which in a regular size class is a popover anchored to this
/// view. Presented as the *content* of a SwiftUI `.sheet` instead, it is embedded as a child of a
/// form-sheet container and left in a cramped column (issue #268).
///
/// The view draws nothing — it is attached with `.background` purely so SwiftUI gives it a
/// laid-out `UIView` to anchor to and a view controller to present from.
struct ShareSheetPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    /// A closure, not a value: `updateUIViewController` runs on every body evaluation of the host,
    /// and building the items renders the drawing twice at full size
    /// (`PKDrawing.lightModeImage`). This way it runs once, when the sheet is presented.
    let activityItems: () -> [Any]
    /// `.any` points the arrow at the anchor; `[]` centres an arrow-less popover on it, for
    /// triggers with nothing left on screen to point at.
    var permittedArrowDirections: UIPopoverArrowDirection = .any
    var onDismiss: () -> Void = {}

    func makeUIViewController(context: Context) -> ShareSheetAnchorController {
        ShareSheetAnchorController()
    }

    func updateUIViewController(_ controller: ShareSheetAnchorController, context: Context) {
        controller.permittedArrowDirections = permittedArrowDirections
        // Reassigned every update so the closure never holds a stale binding. Clearing
        // isPresented here rather than at the call site keeps the flag from disagreeing with
        // what is on screen when the user taps outside the popover.
        controller.onDismiss = {
            isPresented = false
            onDismiss()
        }
        if isPresented {
            controller.presentActivityView(items: activityItems)
        } else {
            controller.dismissActivityView()
        }
    }
}

/// The empty view `ShareSheetPresenter` anchors to, which also does the presenting: a child view
/// controller's `present` is forwarded up to the nearest ancestor that can present, so no window
/// or root-view-controller lookup is needed.
final class ShareSheetAnchorController: UIViewController {
    var permittedArrowDirections: UIPopoverArrowDirection = .any
    var onDismiss: () -> Void = {}

    // UIKit hoists the presentation to an ancestor, so `presentedViewController` is nil here;
    // this weak reference is the only handle on the sheet raised for this anchor.
    private weak var activityViewController: UIActivityViewController?
    // Covers the runloop turn between asking for the presentation and UIKit accepting it:
    // SwiftUI can call updateUIViewController several times inside that window.
    private var isPresentationPending = false

    func presentActivityView(items: @escaping () -> [Any]) {
        guard activityViewController == nil, !isPresentationPending else { return }
        isPresentationPending = true
        // Deferred a turn: presenting from inside a SwiftUI update pass runs while the host is
        // still laying out, the same reason PKCanvasViewWrapper defers becomeFirstResponder()
        DispatchQueue.main.async { [weak self] in
            self?.show(items: items())
        }
    }

    /// A programmatic dismissal does not call `completionWithItemsHandler`, so the caller's
    /// `onDismiss` is fired here instead. A no-op when nothing is presented, which is the common
    /// case: this runs on every update while `isPresented` is false.
    func dismissActivityView() {
        guard let presented = activityViewController else { return }
        activityViewController = nil
        presented.presentingViewController?.dismiss(animated: true)
        onDismiss()
    }

    // With no arrow there is nothing to point at, so the popover is centred on the anchor rather
    // than pushed to one of its edges
    private var sourceRect: CGRect {
        permittedArrowDirections.isEmpty
            ? CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            : view.bounds
    }

    private func show(items: [Any]) {
        isPresentationPending = false
        // A share raised just before the host left the screen has nothing to anchor to; report a
        // dismissal so the caller can undo whatever it did before triggering
        guard !items.isEmpty, view.window != nil else {
            onDismiss()
            return
        }
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // Required, not optional: in a regular size class UIActivityViewController defaults to
        // .popover and raises if presented without a source. The chain is optional because in a
        // compact size class the style is a sheet and there is no popover controller to configure.
        controller.popoverPresentationController?.sourceView = view
        controller.popoverPresentationController?.sourceRect = sourceRect
        controller.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        // Fires for a cancelled share too, including a tap outside the popover
        controller.completionWithItemsHandler = { [weak self] _, _, _, _ in
            guard let self else { return }
            self.activityViewController = nil
            self.onDismiss()
        }
        activityViewController = controller
        present(controller, animated: true)
    }
}

extension View {
    /// Presents a share sheet from UIKit, anchored to this view. Shaped like
    /// `.sheet(isPresented:)` so the call sites read the same way.
    func shareSheet(isPresented: Binding<Bool>,
                    activityItems: @escaping () -> [Any],
                    permittedArrowDirections: UIPopoverArrowDirection = .any,
                    onDismiss: @escaping () -> Void = {}) -> some View {
        background {
            ShareSheetPresenter(isPresented: isPresented,
                                activityItems: activityItems,
                                permittedArrowDirections: permittedArrowDirections,
                                onDismiss: onDismiss)
                // The anchor is invisible and must not take the tap that opened it
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// `item` variant, shaped like `.sheet(item:)`.
    func shareSheet<Item>(item: Binding<Item?>,
                          activityItems: @escaping (Item) -> [Any],
                          permittedArrowDirections: UIPopoverArrowDirection = .any,
                          onDismiss: @escaping () -> Void = {}) -> some View {
        shareSheet(isPresented: Binding(get: { item.wrappedValue != nil },
                                        set: { if !$0 { item.wrappedValue = nil } }),
                   activityItems: {
                       guard let value = item.wrappedValue else { return [] }
                       return activityItems(value)
                   },
                   permittedArrowDirections: permittedArrowDirections,
                   onDismiss: onDismiss)
    }
}
