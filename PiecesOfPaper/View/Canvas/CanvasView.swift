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
    @ObservedObject private(set) var canvasViewModel: CanvasViewModel
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
            guard let drawing = canvasViewModel.document?.entity.drawing else { return }
            canvasView.drawing = drawing
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
        .sheet(isPresented: $canvasViewModel.showTagList,
               onDismiss: {
                   setToolPickerVisible(true)
               },
               content: {
                    if let document = canvasViewModel.document {
                        AddTagView(viewModel: TagListToNoteViewModel(noteDocument: document))
                    }
               }
        )
        .alert("", isPresented: $showUnsavedAlert) {
             Button(role: .destructive) {
                 dismiss()
             } label: {
                 Text("Discard")
             }
             Button("Cancel") {

             }
         } message: {
             Text("Discard changes?")
        }
    }

    private var toolbarItemGroup: ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: archive) {
                Image(systemName: "trash").foregroundColor(.red)
            }
            Button(action: {
                setToolPickerVisible(false)
                canvasViewModel.showTagList.toggle()
                },
                label: {
                    Image(systemName: "tag.circle")
                })
            Button(action: { canvasViewModel.showDrawingInformation.toggle() },
                   label: { Image(systemName: "info.circle") })
            .popover(isPresented: $canvasViewModel.showDrawingInformation) {
                if let document = canvasViewModel.document {
                    NoteInformationView(document: document)
                } else {
                    EmptyView()
                }
            }
            Button(action: {
                setToolPickerVisible(false)
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
            guard let drawing = canvasViewModel.document?.entity.drawing else { return }
            image = drawing.image(
                from: drawing.bounds,
                scale: UIScreen.main.scale
            )
        }

        return UIActivityViewControllerWrapper(activityItems: [image])
    }

    private func archive() {
        if !UserPreference().enabledAutoSave {
            guard let document = canvasViewModel.document, !document.entity.drawing.strokes.isEmpty else {
                dismiss()
                return
            }
            setToolPickerVisible(false)
            showUnsavedAlert = true
            return
        }
        canvasViewModel.archive()
        dismiss()
        reviewRequest()
    }

    private func close() {
        if !UserPreference().enabledAutoSave {
            canvasViewModel.save()
        }

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
    static var viewModel = CanvasViewModel()

    static var previews: some View {
        CanvasView(canvasViewModel: CanvasViewModel())
    }
}
