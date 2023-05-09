//
//  RootView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2022/02/24.
//  Copyright © 2022 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct RootView: View {
    @StateObject var viewModel = AppViewModel()
    @StateObject var canvasViewModel = CanvasViewModel()
//    @State var isShowTagList = false
//    @State var document: NoteDocument?

    var body: some View {
        SideBarList()
        .fullScreenCover(isPresented: $viewModel.showCanvas) {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    Canvas(viewModel: CanvasViewModel())
                }
            } else {
                NavigationView {
                    Canvas(viewModel: CanvasViewModel())
                }
            }
        }
//        .sheet(isPresented: $isShowTagList,
//               content: {
//                   AddTagView(viewModel: TagListToNoteViewModel(noteDocument: document))
//               })
        .onAppear {
            viewModel.hasDrawingPlist = DrawingsPlistConverter.hasDrawingsPlist
            DrawingsPlistConverter.convert()

            guard !UserPreference().shouldGrantiCloud else {
                viewModel.iCloudDenying = true
                return
            }

            viewModel.showCanvas = true
        }
//        .onReceive(NotificationCenter.default.publisher(for: .showAddTagView)) { notification in
//            if let document = notification.userInfo?["document"] as? NoteDocument {
//                self.document = document
//                isShowTagList = true
//            }
//        }
        .alert("", isPresented: $viewModel.iCloudDenying) {
             Button("Use iCloud") {
                 viewModel.openSettingApp()
             }
             Button("Use device storage") {
                 viewModel.switchDeviceStorage()
             }
         } message: {
             Text(viewModel.iCloudDeniedWarningMessage)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
