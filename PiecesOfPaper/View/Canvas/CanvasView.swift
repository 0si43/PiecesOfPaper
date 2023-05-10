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
    @ObservedObject var viewModel: CanvasViewModel
    @Environment(\.dismiss) var dismiss
    @AppStorage("review_requested") var reviewRequested = false

    var tap: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                viewModel.hideExceptPaper.toggle()
                viewModel.showToolPicker = !viewModel.hideExceptPaper
            }
    }

    var discardButton: Alert.Button {
        .destructive(
            Text("Discard"), action: { dismiss() }
        )
    }
    var cancelButton: Alert.Button { .default(Text("Cancel")) }

    var body: some View {
        PKCanvasViewWrapper(drawing: viewModel.document?.entity.drawing,
                            showToolPicker: $viewModel.showToolPicker,
                            saveAction: viewModel.save)
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
                                viewModel.showToolPicker.toggle()
                                viewModel.showTagList.toggle()
                            },
                            label: {
                                Image(systemName: "tag.circle")
                            })
                    }
                    Button(action: { viewModel.showDrawingInformation.toggle() },
                           label: { Image(systemName: "info.circle") })
                    .popover(isPresented: $viewModel.showDrawingInformation) {
                        NoteInformationView(document: viewModel.document!)
                    }
                    Button(action: { viewModel.isShowActivityView.toggle() },
                           label: { Image(systemName: "square.and.arrow.up") })
                    Button(action: close) {
                        Image(systemName: "tray.full")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowActivityView,
                   onDismiss: { viewModel.showToolPicker = true },
                   content: { viewModel.activityViewController })
            .sheet(isPresented: $viewModel.showTagList,
                   onDismiss: { viewModel.showToolPicker = true },
                   content: { AddTagView(viewModel: TagListToNoteViewModel(noteDocument: viewModel.document)) })
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
            guard !(viewModel.document?.entity.drawing.strokes.isEmpty ?? true) else {
                dismiss()
                return
            }
            viewModel.showToolPicker = false
            viewModel.showUnsavedAlert.toggle()
            return
        }
        viewModel.archive()
        // do not send notification

        dismiss()
        reviewRequest()
    }

    private func close() {
        if !UserPreference().enabledAutoSave {
            viewModel.save()
        }

        if viewModel.hasSavedDocument {
            NotificationCenter.default.post(name: .addedNewNote, object: viewModel.document)
        }
        dismiss()
        reviewRequest()
    }

    private func reviewRequest() {
        if viewModel.canReviewRequest,
           !reviewRequested,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            reviewRequested = true
        }
    }
}

struct CanvasView_Previews: PreviewProvider {
    static var viewModel = CanvasViewModel()

    static var previews: some View {
        ForEach(TargetPreviewDevice.allCases) { deviceName in
            CanvasView(viewModel: viewModel)
                .previewDevice(PreviewDevice(rawValue: deviceName.rawValue))
                .previewDisplayName(deviceName.rawValue)
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}
