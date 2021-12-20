//
//  PiecesOfPaperApp.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

@main
struct PiecesOfPaperApp: App {
    @StateObject var viewModel = PiecesOfPaperAppViewModel()
    @StateObject var canvasViewModel = CanvasViewModel()

    private var useICloudButton: Alert.Button {
        .default(Text("Use iCloud"), action: viewModel.openSettingApp)
    }

    private var useDeviceButton: Alert.Button {
        .default(Text("Use device storage"), action: viewModel.switchDeviceStorage)
    }

    var body: some Scene {
        WindowGroup {
                NavigationView {
                    SideBarList(isAppLaunch: $viewModel.isAppLaunch)
                }
                .fullScreenCover(isPresented: $viewModel.isShowCanvas) {
                    NavigationView {
                        Canvas(viewModel: canvasViewModel)
                    }
                }
                .sheet(isPresented: $viewModel.isShowTagList, onDismiss: {
                    TagListRouter.shared.documentForPass = nil
                }) {
                    TagListToNote()
                }
                .onAppear {
                    guard viewModel.isAppLaunch else { return }

                    CanvasRouter.shared.bind(isShowCanvas: $viewModel.isShowCanvas, noteDocument: $canvasViewModel.document)
                    CanvasRouter.shared.openNewCanvas()
                    // I thought this can work, but SwiftUI cannot pass the document data...
                    TagListRouter.shared.bind(isShowTagList: $viewModel.isShowTagList)
                    DrawingsPlistConverter.convert()
                    viewModel.isAppLaunch = false

                    if UserPreference().shouldGrantiCloud {
                        viewModel.iCloudDenying = true
                    }
                }
                .alert(isPresented: $viewModel.iCloudDenying) { () -> Alert in
                    Alert(title: Text(viewModel.iCloudDeniedWarningMessage),
                          primaryButton: useICloudButton,
                          secondaryButton: useDeviceButton)
                }
        }
    }
}
