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
    @AppStorage("onboarding_v3.0.0") var didShowOnboarding = false

    private var useICloudButton: Alert.Button {
        .default(Text("Use iCloud"), action: viewModel.openSettingApp)
    }

    private var useDeviceButton: Alert.Button {
        .default(Text("Use device storage"), action: viewModel.switchDeviceStorage)
    }

    var body: some Scene {
        WindowGroup {
                NavigationView {
                    SideBarList()
                }
                .fullScreenCover(isPresented: $viewModel.isShowCanvas) {
                    NavigationView {
                        Canvas(viewModel: canvasViewModel)
                    }
                }
                .sheet(isPresented: $viewModel.showOnboarding) {
                    Onboarding()
                        .onAppear {
                            didShowOnboarding = true
                        }
                }
                .sheet(isPresented: $viewModel.isShowTagList, onDismiss: {
                    TagListRouter.shared.documentForPass = nil
                }) {
                    TagListToNote()
                }
                .onAppear {
                    CanvasRouter.shared.bind(isShowCanvas: $viewModel.isShowCanvas, noteDocument: $canvasViewModel.document)
                    // I thought this can work, but SwiftUI cannot pass the document data...
                    TagListRouter.shared.bind(isShowTagList: $viewModel.isShowTagList)
                    viewModel.hasDrawingPlist = DrawingsPlistConverter.hasDrawingsPlist
                    DrawingsPlistConverter.convert()

                    guard didShowOnboarding else {
                        viewModel.showOnboarding = true
                        return
                    }

                    guard !UserPreference().shouldGrantiCloud else {
                        viewModel.iCloudDenying = true
                        return
                    }

                    if didShowOnboarding {
                        CanvasRouter.shared.openNewCanvas()
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
