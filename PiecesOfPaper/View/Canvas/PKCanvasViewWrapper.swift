import SwiftUI
import PencilKit

struct PKCanvasViewWrapper: UIViewRepresentable {
    @Binding private var canvasView: PKCanvasView
    @Binding private var toolPicker: PKToolPicker
    private let isToolPickerVisible: Bool
    private let saveAction: (PKDrawing) -> Void
    private let onToggleUI: (() -> Void)?
    private let onRevealUI: (() -> Void)?
    private var defaultTool = PKInkingTool(.pen, color: .black, width: 1)
    private var previousTool: PKTool
    private var currentTool: PKTool

    init(canvasView: Binding<PKCanvasView>,
         toolPicker: Binding<PKToolPicker>,
         isToolPickerVisible: Bool,
         saveAction: @escaping (PKDrawing) -> Void,
         onToggleUI: (() -> Void)? = nil,
         onRevealUI: (() -> Void)? = nil) {
        self._canvasView = canvasView
        self._toolPicker = toolPicker
        self.isToolPickerVisible = isToolPickerVisible
        self.saveAction = saveAction
        self.onToggleUI = onToggleUI
        self.onRevealUI = onRevealUI
        self.previousTool = defaultTool
        self.currentTool = defaultTool
    }

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.maximumZoomScale = 8.0
        #if targetEnvironment(simulator)
        // The Simulator has no Apple Pencil; allow mouse (finger) input so drawing is testable
        canvasView.drawingPolicy = .anyInput
        #endif
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
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updateContentSizeIfNeeded(canvasView)

        guard PreferenceRepository().getEnabledAutoSave() else { return }
        parent.saveAction(canvasView.drawing)
    }

    private func updateContentSizeIfNeeded(_ canvasView: PKCanvasView) {
        guard !canvasView.drawing.bounds.isNull,
              PreferenceRepository().getEnabledInfiniteScroll() else { return }
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
        default:                revealUI()
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

    // Brings the whole chrome back rather than only the picker: with the picker
    // visible a finger draws, so the tap that used to restore the control panel
    // would be consumed and the panel left unreachable
    private func revealUI() {
        parent.onRevealUI?()
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
                        saveAction: { _ in })
}
