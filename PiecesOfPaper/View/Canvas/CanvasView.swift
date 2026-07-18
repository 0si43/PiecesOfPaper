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
    @State var canvasViewModel: CanvasViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @AppStorage("review_requested") private var reviewRequested = false
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var hideExceptPaper = true
    @State private var isShowActivityView = false
    @State private var showUnsavedAlert = false
    @State private var windowSize = CGSize.zero
    @State private var isDrawingLoaded = false
    @State private var hasAppliedInitialContentSize = false

    private var tapGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                hideExceptPaper.toggle()
                setToolPickerVisible(!hideExceptPaper)
            }
    }

    private func setToolPickerVisible(_ isVisible: Bool) {
        toolPicker.setVisible(isVisible, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    var body: some View {
        // Not a GeometryReader: wrapping the canvas in one breaks Apple Pencil
        // input and stroke rendering on device (#187).
        canvas
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                windowSize = size
                applyInitialContentSizeIfNeeded()
            }
    }

    private var canvas: some View {
        PKCanvasViewWrapper(canvasView: $canvasView,
                            toolPicker: $toolPicker,
                            saveAction: { canvasViewModel.save(drawing: $0) })
        .onAppear {
            canvasView.drawing = canvasViewModel.note.entity.drawing
            isDrawingLoaded = true
            applyInitialContentSizeIfNeeded()
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
                canvasViewModel.save(drawing: canvasView.drawing) { success in
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
               isPresented: $canvasViewModel.showSaveFailedAlert) {
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

    private func applyInitialContentSizeIfNeeded() {
        guard isDrawingLoaded, windowSize != .zero, !hasAppliedInitialContentSize else { return }
        hasAppliedInitialContentSize = true
        initialContentSize(windowSize: windowSize)
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
                canvasViewModel.showDrawingInformation.toggle()
            } label: {
                Image(systemName: "info.circle")
            }
            .accessibilityLabel("Note Information")
            .popover(isPresented: $canvasViewModel.showDrawingInformation) {
                NoteInformationView(note: canvasViewModel.note)
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
            image = canvasViewModel.note.entity.drawing.image(
                from: canvasViewModel.note.entity.drawing.bounds,
                scale: displayScale
            )
        }

        return UIActivityViewControllerWrapper(activityItems: [image])
    }

    private func done() {
        if canvasViewModel.hasUnsavedChanges(comparedTo: canvasView.drawing) {
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
        if canvasViewModel.canReviewRequest,
           !reviewRequested,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            reviewRequested = true
        }
    }
}

#Preview {
    CanvasView(canvasViewModel: CanvasViewModel(note: NoteData.createTestData()))
}
