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
    @EnvironmentObject var canvasViewModel: CanvasViewModel
    @Environment(\.dismiss) var dismiss
    @AppStorage("review_requested") var reviewRequested = false
    @State var hideExceptPaper = true
    @State var showToolPicker = false
    @State var isShowActivityView = false

    var discardButton: Alert.Button {
        .destructive(
            Text("Discard"), action: { dismiss() }
        )
    }
    var cancelButton: Alert.Button { .default(Text("Cancel")) }

    var body: some View {
        PKCanvasViewWrapper(drawing: canvasViewModel.document.entity.drawing,
                            showToolPicker: $showToolPicker,
                            saveAction: canvasViewModel.save)
        .onAppear {
            hideExceptPaper = true
        }
        .onTapGesture {
            hideExceptPaper.toggle()
            showToolPicker = !hideExceptPaper
        }
        .statusBar(hidden: hideExceptPaper)
        .navigationBarHidden(hideExceptPaper)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            toolbarItemGroup
        }
        .sheet(isPresented: $isShowActivityView,
               onDismiss: { showToolPicker = true },
               content: { activityViewController })
        .sheet(isPresented: $canvasViewModel.showTagList,
               onDismiss: { showToolPicker = true },
               content: { AddTagView(viewModel: TagListToNoteViewModel(noteDocument: canvasViewModel.document)) })
        .alert(isPresented: $canvasViewModel.showUnsavedAlert) { () -> Alert in
            Alert(title: Text("Are you sure you want to discard the changes you made?"),
                  primaryButton: discardButton,
                  secondaryButton: cancelButton)
        }
    }

    private var toolbarItemGroup: ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: archive) {
                Image(systemName: "trash").foregroundColor(.red)
            }
            Button(action: {
                showToolPicker = false
                canvasViewModel.showTagList.toggle()
                },
                label: {
                    Image(systemName: "tag.circle")
                })
            Button(action: { canvasViewModel.showDrawingInformation.toggle() },
                   label: { Image(systemName: "info.circle") })
            .popover(isPresented: $canvasViewModel.showDrawingInformation) {
                NoteInformationView(document: canvasViewModel.document)
            }
            Button(action: {
                showToolPicker = false
                isShowActivityView.toggle()
            },
                   label: { Image(systemName: "square.and.arrow.up") })
            Button(action: close) {
                Image(systemName: "tray.full")
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

    private func archive() {
        if !UserPreference().enabledAutoSave {
            guard !canvasViewModel.document.entity.drawing.strokes.isEmpty else {
                dismiss()
                return
            }
            showToolPicker = false
            canvasViewModel.showUnsavedAlert.toggle()
            return
        }
        canvasViewModel.archive()
        // do not send notification

        dismiss()
        reviewRequest()
    }

    private func close() {
        if !UserPreference().enabledAutoSave {
            canvasViewModel.save()
        }

        if canvasViewModel.hasSavedDocument {
            NotificationCenter.default.post(name: .addedNewNote, object: canvasViewModel.document)
        }
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

struct CanvasView_Previews: PreviewProvider {
    static var viewModel = CanvasViewModel()

    static var previews: some View {
        ForEach(TargetPreviewDevice.allCases) { deviceName in
            CanvasView()
                .environmentObject(CanvasViewModel())
                .previewDevice(PreviewDevice(rawValue: deviceName.rawValue))
                .previewDisplayName(deviceName.rawValue)
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}
