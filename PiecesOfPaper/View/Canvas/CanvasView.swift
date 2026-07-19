//
//  CanvasView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/29.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit
import StoreKit
import LinkPresentation

struct CanvasView: View {
    @State private var note: NoteData
    @Environment(NoteStore.self) private var noteStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @AppStorage("review_requested") private var reviewRequested = false
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var hideExceptPaper = true
    @State private var isShowActivityView = false
    @State private var showUnsavedAlert = false
    @State private var showDrawingInformation = false
    @State private var showSaveFailedAlert = false
    @State private var savingDrawing: PKDrawing?
    @State private var queuedSave: (drawing: PKDrawing, completion: ((Bool) -> Void)?)?

    init(note: NoteData) {
        self._note = State(initialValue: note)
    }

    private var tapGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                toggleUIVisibility()
            }
    }

    private func toggleUIVisibility() {
        hideExceptPaper.toggle()
        setToolPickerVisible(!hideExceptPaper)
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
        noteStore.save(drawing: drawing, to: note) { savedNote in
            savingDrawing = nil
            if let savedNote {
                note = savedNote
            } else {
                showSaveFailedAlert = true
            }
            completion?(savedNote != nil)
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
                            saveAction: { save(drawing: $0) },
                            onToggleUI: { toggleUIVisibility() })
        .onAppear {
            canvasView.drawing = note.entity.drawing
            initialContentSize(windowSize: windowSize)
            hideExceptPaper = true
        }
        .gesture(tapGesture)
        .statusBar(hidden: hideExceptPaper)
        .toolbar(hideExceptPaper ? .hidden : .visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            toolbarItemGroup
        }
        .sheet(isPresented: $isShowActivityView,
               onDismiss: {
                   setToolPickerVisible(true)
               },
               content: { activityViewController })
        .alert("", isPresented: $showUnsavedAlert) {
            Button {
                save(drawing: canvasView.drawing) { success in
                    if success {
                        closeCanvas()
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
         } message: {
             Text("Save changes?")
        }
        .alert("Failed to save the note",
               isPresented: $showSaveFailedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your latest changes may not be persisted.")
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

    private var toolbarItemGroup: ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                showDrawingInformation.toggle()
            } label: {
                Image(systemName: "info.circle")
            }
            .accessibilityLabel("Note Information")
            .popover(isPresented: $showDrawingInformation) {
                NoteInformationView(note: note)
            }
            Button {
                setToolPickerVisible(false)
                isShowActivityView.toggle()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share")
            Button(action: done) {
                Text("Done")
            }
        }
    }

    private var activityViewController: UIActivityViewControllerWrapper {
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        trait.performAsCurrent {
            image = note.entity.drawing.image(
                from: note.entity.drawing.bounds,
                scale: displayScale
            )
        }

        return UIActivityViewControllerWrapper(activityItems: [image])
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
            SKStoreReviewController.requestReview(in: windowScene)
            reviewRequested = true
        }
    }
}

#Preview {
    CanvasView(note: NoteData.createTestData())
        .environment(NoteStore())
}
