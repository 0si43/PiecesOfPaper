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
        .sheet(isPresented: $viewModel.isShowTagList,
               onDismiss: {
                   TagListRouter.shared.documentForPass = nil
               }, content: {
                   TagListToNote()
               })
        .onAppear {
            TagListRouter.shared.bind(isShowTagList: $viewModel.isShowTagList)
            viewModel.hasDrawingPlist = DrawingsPlistConverter.hasDrawingsPlist
            DrawingsPlistConverter.convert()

            guard !UserPreference().shouldGrantiCloud else {
                viewModel.iCloudDenying = true
                return
            }

            viewModel.showCanvas = true
        }
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
