import SwiftUI
import PencilKit
import StoreKit

struct CanvasView: View {
    @State private var note: NoteData
    @Environment(NoteStore.self) private var noteStore
    @Environment(PreferenceStore.self) private var preferenceStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("review_requested") private var reviewRequested = false
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    // Not persisted and not reset in onAppear: RootSplitView gives the cover an
    // .id(note.id), so switching notes rebuilds this view with the initial value
    @State private var hideExceptPaper = false
    @State private var isShowActivityView = false
    @State private var showUnsavedAlert = false
    @State private var showDrawingInformation = false
    @State private var showSaveFailedAlert = false
    @State private var saveFailedMessage = ""
    @State private var savingDrawing: PKDrawing?
    @State private var queuedSave: (drawing: PKDrawing, completion: ((Bool) -> Void)?)?

    init(note: NoteData) {
        self._note = State(initialValue: note)
    }

    private var tapGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                // Paper-only mode hides the tool picker, and .default degrades to pencil-only
                // without one, so entering it would leave a finger-drawing user unable to draw.
                // Normally moot — the drawing gesture recognizer takes the tap first
                guard hideExceptPaper || UIPencilInteraction.prefersPencilOnlyDrawing else { return }
                toggleUIVisibility()
            }
    }

    private func toggleUIVisibility() {
        hideExceptPaper.toggle()
        setToolPickerVisible(!hideExceptPaper)
    }

    private func revealUI() {
        hideExceptPaper = false
        setToolPickerVisible(true)
    }

    private func setToolPickerVisible(_ isVisible: Bool) {
        toolPicker.setVisible(isVisible, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    private func hasUnsavedChanges() -> Bool {
        let drawing = canvasView.drawing
        return drawing != note.entity.drawing
            && drawing != savingDrawing
            && drawing != queuedSave?.drawing
    }

    // Saves are serialized: concurrent UIDocument writes to one file can complete
    // out of order and resurrect an older drawing
    private func save(drawing: PKDrawing, completion: ((Bool) -> Void)? = nil) {
        guard savingDrawing == nil else {
            queuedSave = (drawing, completion)
            return
        }
        savingDrawing = drawing
        Task {
            do {
                note = try await noteStore.save(drawing: drawing, to: note)
                savingDrawing = nil
                completion?(true)
            } catch {
                savingDrawing = nil
                saveFailedMessage = error.localizedDescription
                showSaveFailedAlert = true
                completion?(false)
            }
            if let next = queuedSave {
                queuedSave = nil
                save(drawing: next.drawing, completion: next.completion)
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            canvas(windowSize: geometry.size)
        }
    }

    private func canvas(windowSize: CGSize) -> some View {
        PKCanvasViewWrapper(canvasView: $canvasView,
                            toolPicker: $toolPicker,
                            isToolPickerVisible: !hideExceptPaper,
                            // The store is captured explicitly: without a capture list these
                            // close over the whole view, which reads @Environment outside body
                            isAutoSaveEnabled: { [preferenceStore] in preferenceStore.enabledAutoSave },
                            isInfiniteScrollEnabled: { [preferenceStore] in preferenceStore.enabledInfiniteScroll },
                            saveAction: { save(drawing: $0) },
                            onToggleUI: { toggleUIVisibility() },
                            onRevealUI: { revealUI() })
        .onAppear {
            canvasView.drawing = note.entity.drawing
            initialContentSize(windowSize: windowSize)
        }
        .gesture(tapGesture)
        // The overlay is attached outside the gesture so its buttons take the tap
        // first, and it never contributes to the layout of the canvas below it
        .overlay(alignment: .topTrailing) {
            controlPanel
        }
        // Both bars are pinned to a constant: a top safe-area inset that changes
        // with the chrome shifts the drawing inside the PKCanvasView
        .statusBar(hidden: true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("", isPresented: $showUnsavedAlert) {
            unsavedAlertActions
        } message: {
            Text("Save changes?")
        }
        .alert("Failed to save the note",
               isPresented: $showSaveFailedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your latest changes may not be persisted.\n\(saveFailedMessage)")
        }
    }

    @ViewBuilder
    private var unsavedAlertActions: some View {
        Button {
            save(drawing: canvasView.drawing) { success in
                if success {
                    closeCanvas()
                } else {
                    setToolPickerVisible(!hideExceptPaper)
                }
            }
        } label: {
            Text("Save")
        }
        Button(role: .destructive) {
            dismiss()
        } label: {
            Text("Discard")
        }
        // Spelled out rather than left to SwiftUI's synthesized cancel button,
        // which gives no hook to undo the setToolPickerVisible(false) in done()
        Button(role: .cancel) {
            setToolPickerVisible(!hideExceptPaper)
        } label: {
            Text("Cancel")
        }
    }

    // MARK: - Window Adjustment

    private func isDrawingWider(than windowSize: CGSize) -> Bool {
        windowSize.width < canvasView.drawing.bounds.maxX
    }

    private func isDrawingHigher(than windowSize: CGSize) -> Bool {
        windowSize.height < canvasView.drawing.bounds.maxY
    }

    private func initialContentSize(windowSize: CGSize) {
        guard !canvasView.drawing.bounds.isNull else { return }

        if isDrawingWider(than: windowSize), isDrawingHigher(than: windowSize) {
            canvasView.contentSize = .init(width: canvasView.drawing.bounds.maxX,
                                           height: canvasView.drawing.bounds.maxY)
        } else if isDrawingWider(than: windowSize), !isDrawingHigher(than: windowSize) {
            canvasView.contentSize = .init(width: canvasView.drawing.bounds.maxX,
                                           height: windowSize.height)
        } else if !isDrawingWider(than: windowSize), isDrawingHigher(than: windowSize) {
            canvasView.contentSize = .init(width: windowSize.width,
                                           height: canvasView.drawing.bounds.maxY)
        }

        canvasView.contentOffset = .zero
    }

    // Measured from the safe area, which already clears the sensor housing on iPhone
    private var panelMargin: CGFloat {
        horizontalSizeClass == .compact ? 12 : 20
    }

    private var controlPanel: some View {
        HStack(spacing: 4) {
            Button {
                showDrawingInformation.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .imageScale(.large)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Note Information")
            .popover(isPresented: $showDrawingInformation) {
                NoteInformationView(note: note)
            }
            Button {
                setToolPickerVisible(false)
                isShowActivityView = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .imageScale(.large)
                    // The arrow overshoots the top of the symbol's box, so centering the
                    // box hangs the tray below its neighbours. Apple's toolbars line the
                    // tray's bottom edge up with theirs instead and let the arrow stick out
                    .offset(y: -2)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Share")
            // Attached to the button, not the panel, so the popover's arrow points at the glyph
            .shareSheet(isPresented: $isShowActivityView,
                        activityItems: { shareActivityItems },
                        onDismiss: { setToolPickerVisible(!hideExceptPaper) })
            Button(action: done) {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(height: 44)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Done")
        }
        .padding(.horizontal, 8)
        // The navigation bar tinted its items with the label color, not the accent color
        .tint(.primary)
        // A material alone is nearly invisible on a blank sheet; the border carries the outline
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.separator, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        // Padding sits outside the capsule, so taps in the margin fall through to the canvas
        .padding(.top, panelMargin)
        .padding(.trailing, panelMargin)
        // opacity alone leaves the panel hit-testable and readable by VoiceOver
        .opacity(hideExceptPaper ? 0 : 1)
        .allowsHitTesting(!hideExceptPaper)
        .accessibilityHidden(hideExceptPaper)
        // Scoped to this subtree: an animated transaction reaching PKCanvasViewWrapper
        // would put the PencilKit renderer in an animation it does not expect
        .animation(.easeInOut(duration: 0.2), value: hideExceptPaper)
    }

    // Read when the sheet is presented, not on every body evaluation: this renders the whole
    // drawing twice at display scale, and the body re-runs on every autosave
    private var shareActivityItems: [Any] {
        [NoteShareItemSource(image: note.entity.drawing.lightModeImage(scale: displayScale),
                             updatedDate: note.entity.updatedDate)]
    }

    private func done() {
        if hasUnsavedChanges() {
            setToolPickerVisible(false)
            showUnsavedAlert = true
            return
        }

        closeCanvas()
    }

    private func closeCanvas() {
        dismiss()
        reviewRequest()
    }

    private func reviewRequest() {
        if noteStore.canRequestReview,
           !reviewRequested,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: windowScene)
            reviewRequested = true
        }
    }
}

#if DEBUG
#Preview {
    CanvasView(note: NoteData.createTestData())
        .environment(NoteStore())
        .environment(PreferenceStore())
}
#endif
