import SwiftUI
import PencilKit

struct PKCanvasViewWrapper: UIViewRepresentable {
    @Binding private var canvasView: PKCanvasView
    @Binding private var toolPicker: PKToolPicker
    private let isToolPickerVisible: Bool
    // Closures rather than Bool: updateUIView is empty, so Coordinator.parent is
    // frozen at the value makeCoordinator() captured, and a copied flag would go
    // stale when the setting changes while the canvas is open
    private let isAutoSaveEnabled: () -> Bool
    private let isInfiniteScrollEnabled: () -> Bool
    private let saveAction: (PKDrawing) -> Void
    private let onToggleUI: (() -> Void)?
    private var defaultTool = PKInkingTool(.pen, color: .black, width: 1)
    private var previousTool: PKTool
    private var currentTool: PKTool

    init(canvasView: Binding<PKCanvasView>,
         toolPicker: Binding<PKToolPicker>,
         isToolPickerVisible: Bool,
         isAutoSaveEnabled: @escaping () -> Bool,
         isInfiniteScrollEnabled: @escaping () -> Bool,
         saveAction: @escaping (PKDrawing) -> Void,
         onToggleUI: (() -> Void)? = nil) {
        self._canvasView = canvasView
        self._toolPicker = toolPicker
        self.isToolPickerVisible = isToolPickerVisible
        self.isAutoSaveEnabled = isAutoSaveEnabled
        self.isInfiniteScrollEnabled = isInfiniteScrollEnabled
        self.saveAction = saveAction
        self.onToggleUI = onToggleUI
        self.previousTool = defaultTool
        self.currentTool = defaultTool
    }

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.maximumZoomScale = 8.0
        #if targetEnvironment(simulator)
        // The Simulator has no Apple Pencil; allow mouse (finger) input so drawing is testable
        canvasView.drawingPolicy = .anyInput
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
            canvasView.drawingPolicy = .pencilOnly
        }
        #endif
        toolPicker.showsDrawingPolicyControls = false
        toolPicker.addObserver(canvasView)
        toolPicker.selectedTool = defaultTool
        // becomeFirstResponder() is a no-op while the view has no window, and
        // makeUIView runs before SwiftUI installs it
        let canvas = canvasView
        let picker = toolPicker
        let visible = isToolPickerVisible
        DispatchQueue.main.async {
            picker.setVisible(visible, forFirstResponder: canvas)
            canvas.becomeFirstResponder()
        }
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: PKCanvasViewWrapper
        init(_ canvasViewWrapper: PKCanvasViewWrapper) {
            self.parent = canvasViewWrapper
            super.init()
            canvasViewWrapper.canvasView.delegate = self
            canvasViewWrapper.toolPicker.addObserver(self)
            let pencilInteraction = UIPencilInteraction()
            pencilInteraction.delegate = self
            parent.canvasView.addInteraction(pencilInteraction)

            #if targetEnvironment(simulator)
            // Under .anyInput a single tap starts a stroke and never reaches
            // CanvasView's TapGesture, so the Simulator toggles the UI with a
            // two-finger tap instead (Option+click)
            let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(toggleUI))
            twoFingerTap.numberOfTouchesRequired = 2
            parent.canvasView.addGestureRecognizer(twoFingerTap)
            #endif
        }

        #if targetEnvironment(simulator)
        @objc private func toggleUI() {
            parent.onToggleUI?()
        }
        #endif
    }
}

// MARK: - PKCanvasViewDelegate
extension PKCanvasViewWrapper.Coordinator: PKCanvasViewDelegate {
    // Both preference reads live here rather than in the helper below:
    // PKCanvasViewDelegate is NS_SWIFT_UI_ACTOR, so this witness is MainActor
    // isolated and may touch the @MainActor PreferenceStore; the private helper
    // is not a witness and inherits no isolation
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if parent.isInfiniteScrollEnabled() {
            updateContentSizeIfNeeded(canvasView)
        }

        guard parent.isAutoSaveEnabled() else { return }
        parent.saveAction(canvasView.drawing)
    }

    private func updateContentSizeIfNeeded(_ canvasView: PKCanvasView) {
        guard !canvasView.drawing.bounds.isNull else { return }
        let drawingWidth = canvasView.drawing.bounds.maxX
        if canvasView.contentSize.width * 9 / 10 < drawingWidth {
            canvasView.contentSize.width += canvasView.frame.width
        }

        let drawingHeight = canvasView.drawing.bounds.maxY
        if canvasView.contentSize.height * 9 / 10 < drawingHeight {
            canvasView.contentSize.height += canvasView.frame.height
        }
    }

}

// MARK: - PKToolPickerObserver
extension PKCanvasViewWrapper.Coordinator: PKToolPickerObserver {
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        parent.previousTool = parent.currentTool
        parent.currentTool = toolPicker.selectedTool
    }
}

// MARK: - UIPencilInteractionDelegate
extension PKCanvasViewWrapper.Coordinator: UIPencilInteractionDelegate {
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        guard !parent.toolPicker.isVisible else { return }
        let action = UIPencilInteraction.preferredTapAction
        switch action {
        case .switchPrevious:   switchPreviousTool()
        case .switchEraser:     switchEraser()
        default:                showToolPicker()
        }
    }

    private func switchPreviousTool() {
        parent.toolPicker.selectedTool = parent.previousTool
    }

    private func switchEraser() {
        if parent.currentTool is PKEraserTool {
            parent.toolPicker.selectedTool = parent.previousTool
        } else {
            parent.toolPicker.selectedTool = PKEraserTool(.vector)
        }
    }

    private func showToolPicker() {
        parent.toolPicker.setVisible(!parent.toolPicker.isVisible, forFirstResponder: parent.canvasView)
        parent.canvasView.becomeFirstResponder()
    }
}

// MARK: - UIScrollViewDelegate
extension PKCanvasViewWrapper.Coordinator: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        parent.canvasView
    }
}

#Preview {
    @Previewable @State var canvasView = PKCanvasView()
    @Previewable @State var toolPicker = PKToolPicker()
    PKCanvasViewWrapper(canvasView: $canvasView,
                        toolPicker: $toolPicker,
                        isToolPickerVisible: true,
                        isAutoSaveEnabled: { true },
                        isInfiniteScrollEnabled: { true },
                        saveAction: { _ in })
}
