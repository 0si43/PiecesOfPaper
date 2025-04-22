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
    @StateObject var canvasViewModel: CanvasViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("review_requested") private var reviewRequested = false
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var hideExceptPaper = true
    @State private var isShowActivityView = false
    @State private var showUnsavedAlert = false

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
        PKCanvasViewWrapper(canvasView: $canvasView,
                            toolPicker: $toolPicker,
                            saveAction: canvasViewModel.save)
        .onAppear {
            canvasView.drawing = canvasViewModel.document.entity.drawing
            initialContentSize()
            hideExceptPaper = true
        }
        .gesture(tapGesture)
        .statusBar(hidden: hideExceptPaper)
        .navigationBarHidden(hideExceptPaper)
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
                canvasViewModel.document.entity.drawing = canvasView.drawing
                canvasViewModel.save()
                closeCanvas()
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
    }

    // MARK: - Window Adjustment

    private var isDrawingWiderThanWindow: Bool {
        UIScreen.main.bounds.width < canvasView.drawing.bounds.maxX
    }

    private var isDrawingHigherThanWindow: Bool {
        UIScreen.main.bounds.height < canvasView.drawing.bounds.maxY
    }

    private func initialContentSize() {
        guard !canvasView.drawing.bounds.isNull else { return }

        if isDrawingWiderThanWindow, isDrawingHigherThanWindow {
            canvasView.contentSize = .init(width: canvasView.drawing.bounds.maxX,
                                           height: canvasView.drawing.bounds.maxY)
        } else if isDrawingWiderThanWindow, !isDrawingHigherThanWindow {
            canvasView.contentSize = .init(width: canvasView.drawing.bounds.maxX,
                                           height: UIScreen.main.bounds.height)
        } else if !isDrawingWiderThanWindow, isDrawingHigherThanWindow {
            canvasView.contentSize = .init(width: UIScreen.main.bounds.width,
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
            .popover(isPresented: $canvasViewModel.showDrawingInformation) {
                NoteInformationView(document: canvasViewModel.document)
            }
            Button {
                setToolPickerVisible(false)
                isShowActivityView.toggle()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            Button(action: done) {
                Text("Done")
            }
        }
    }

    private var activityViewController: UIActivityViewControllerWrapper {
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        trait.performAsCurrent {
            image = canvasViewModel.document.entity.drawing.image(
                from: canvasViewModel.document.entity.drawing.bounds,
                scale: UIScreen.main.scale
            )
        }

        return UIActivityViewControllerWrapper(activityItems: [image])
    }

    private func done() {
        if canvasView.drawing != canvasViewModel.document.entity.drawing {
            setToolPickerVisible(false)
            showUnsavedAlert = true
            return
        }

        closeCanvas()
    }

    private func closeCanvas() {
        dismiss()
        reviewRequest()
        NotificationCenter.default.post(name: .dismissCanvasView, object: nil)
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

struct CanvasView_Previews: PreviewProvider {
    static var viewModel = CanvasViewModel(noteDocument: NoteDocument.createTestData())

    static var previews: some View {
        CanvasView(canvasViewModel: viewModel)
    }
}
