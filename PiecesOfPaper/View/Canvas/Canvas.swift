//
//  Canvas.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/29.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit
import StoreKit
import LinkPresentation

struct Canvas: View {
    @ObservedObject var viewModel = CanvasViewModel()
    @State private var canvasView = PKCanvasView()
    @State var isShowActivityView = false {
        didSet {
            if isShowActivityView == true {
                toolPicker.setVisible(false, forFirstResponder: canvasView)
            }
        }
    }

    @Environment(\.presentationMode) var presentationMode
    @AppStorage("review_requested") var reviewRequested = false

    var delegateBridge: CanvasDelegateBridgeObject
    var toolPicker = PKToolPicker()
    var activityViewController: UIActivityViewControllerWrapper {
        let drawing = canvasView.drawing
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        trait.performAsCurrent {
            image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
        }

        return UIActivityViewControllerWrapper(activityItems: [image, delegateBridge])
    }

    var tap: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                viewModel.hideExceptPaper.toggle()
                toolPicker.addObserver(canvasView)
                toolPicker.setVisible(!viewModel.hideExceptPaper, forFirstResponder: canvasView)
                canvasView.becomeFirstResponder()
            }
    }

    var discardButton: Alert.Button {
        .destructive(
            Text("Discard"), action: { presentationMode.wrappedValue.dismiss() }
        )
    }
    var cancelButton: Alert.Button { .default(Text("Cancel")) }

    init(noteDocument: NoteDocument?) {
        delegateBridge = CanvasDelegateBridgeObject(toolPicker: toolPicker)
        if let noteDocument = noteDocument {
            viewModel.document = noteDocument
            canvasView.drawing = noteDocument.entity.drawing
        }

        delegateBridge.canvas = self
        canvasView.delegate = delegateBridge
        addPencilInteraction()
    }

    private func addPencilInteraction() {
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = delegateBridge
        canvasView.addInteraction(pencilInteraction)
    }

    var body: some View {
        PKCanvasViewWrapper(canvasView: $canvasView)
            .gesture(tap)
            .navigationBarTitleDisplayMode(.inline)
            .statusBar(hidden: viewModel.hideExceptPaper)
            .navigationBarHidden(viewModel.hideExceptPaper)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: archive) {
                        Image(systemName: "arrow.down.square").foregroundColor(.red)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.document != nil {
                        Button(action: {
                            toolPicker.setVisible(false, forFirstResponder: canvasView)
                            viewModel.showTagList.toggle()
                        }) {
                                Image(systemName: "tag.circle")
                        }
                    }
                    Button(action: { viewModel.showDrawingInformation.toggle() }) {
                            Image(systemName: "info.circle")
                    }
                    .popover(isPresented: $viewModel.showDrawingInformation) {
                        NoteInformation(document: viewModel.document)
                    }
                    Button(action: { isShowActivityView.toggle() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: close) {
                        Image(systemName: "tray.full")
                    }
                }
            }
            .sheet(isPresented: $isShowActivityView,
                   onDismiss: { toolPicker.setVisible(true, forFirstResponder: canvasView) }) {
                activityViewController
            }
            .sheet(isPresented: $viewModel.showTagList) {
                TagListToNote(viewModel: TagListToNoteViewModel(noteDocument: viewModel.document))
            }
            .alert(isPresented: $viewModel.showUnsavedAlert) { () -> Alert in
                Alert(title: Text("Are you sure you want to discard the changes you made?"),
                      primaryButton: discardButton,
                      secondaryButton: cancelButton)
            }
    }

    private func archive() {
        if !UserPreference().enabledAutoSave {
            guard !canvasView.drawing.strokes.isEmpty else {
                presentationMode.wrappedValue.dismiss()
                return
            }
            toolPicker.setVisible(false, forFirstResponder: canvasView)
            viewModel.showUnsavedAlert.toggle()
            return
        }
        viewModel.archive()
        NotificationCenter.default.post(name: .addedNewNote, object: viewModel.document)
        presentationMode.wrappedValue.dismiss()
        reviewRequest()
    }

    private func close() {
        if !UserPreference().enabledAutoSave {
            viewModel.save(drawing: canvasView.drawing)
        }
        NotificationCenter.default.post(name: .addedNewNote, object: viewModel.document)
        presentationMode.wrappedValue.dismiss()
        reviewRequest()
    }

    private func reviewRequest() {
        if let windowScene = UIApplication.shared.windows.first?.windowScene,
           viewModel.canReviewRequest,
           !reviewRequested {
            SKStoreReviewController.requestReview(in: windowScene)
            reviewRequested = true
        }
    }
}

// MARK: - PreviewProvider
// struct Canvas_Previews: PreviewProvider {
//    static var previews: some View {
//        
//    }
// }
