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
    @ObservedObject var viewModel: CanvasViewModel

    @Environment(\.presentationMode) var presentationMode
    @AppStorage("review_requested") var reviewRequested = false

    var tap: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                viewModel.hideExceptPaper.toggle()
                viewModel.setVisibleToolPicker(!viewModel.hideExceptPaper)
                viewModel.canvasView.becomeFirstResponder()
            }
    }

    var discardButton: Alert.Button {
        .destructive(
            Text("Discard"), action: { presentationMode.wrappedValue.dismiss() }
        )
    }
    var cancelButton: Alert.Button { .default(Text("Cancel")) }

    var body: some View {
        PKCanvasViewWrapper(canvasView: $viewModel.canvasView)
            .gesture(tap)
            .navigationBarTitleDisplayMode(.inline)
            .statusBar(hidden: viewModel.hideExceptPaper)
            .navigationBarHidden(viewModel.hideExceptPaper)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: archive) {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                    if viewModel.document != nil {
                        Button(action: {
                                viewModel.setVisibleToolPicker(false)
                                viewModel.showTagList.toggle()
                            },
                            label: {
                                Image(systemName: "tag.circle")
                            })
                    }
                    Button(action: { viewModel.showDrawingInformation.toggle() },
                           label: { Image(systemName: "info.circle") })
                    .popover(isPresented: $viewModel.showDrawingInformation) {
                        NoteInformation(document: viewModel.document)
                    }
                    Button(action: { viewModel.isShowActivityView.toggle() },
                           label: { Image(systemName: "square.and.arrow.up") })
                    Button(action: close) {
                        Image(systemName: "tray.full")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowActivityView,
                   onDismiss: { viewModel.setVisibleToolPicker(true) },
                   content: { viewModel.activityViewController })
            .sheet(isPresented: $viewModel.showTagList,
                   onDismiss: { viewModel.setVisibleToolPicker(true) },
                   content: { TagListToNote(viewModel: TagListToNoteViewModel(noteDocument: viewModel.document)) })
            .alert(isPresented: $viewModel.showUnsavedAlert) { () -> Alert in
                Alert(title: Text("Are you sure you want to discard the changes you made?"),
                      primaryButton: discardButton,
                      secondaryButton: cancelButton)
            }
            .onAppear {
                viewModel.hideExceptPaper = true
            }
    }

    private func archive() {
        if !UserPreference().enabledAutoSave {
            guard !viewModel.canvasView.drawing.strokes.isEmpty else {
                presentationMode.wrappedValue.dismiss()
                return
            }
            viewModel.setVisibleToolPicker(false)
            viewModel.showUnsavedAlert.toggle()
            return
        }
        viewModel.archive()
        // do not send notification

        presentationMode.wrappedValue.dismiss()
        reviewRequest()
    }

    private func close() {
        if !UserPreference().enabledAutoSave {
            viewModel.save(drawing: viewModel.canvasView.drawing)
        }

        if viewModel.hasSavedDocument {
            NotificationCenter.default.post(name: .addedNewNote, object: viewModel.document)
        }
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

struct Canvas_Previews: PreviewProvider {
    static var viewModel = CanvasViewModel(noteDocument: NoteDocument.preview)
    
    static var previews: some View {
        ForEach(TargetPreviewDevice.allCases) { deviceName in
            Canvas(viewModel: viewModel)
                .previewDevice(PreviewDevice(rawValue: deviceName.rawValue))
                .previewDisplayName(deviceName.rawValue)
        }
    }
}
