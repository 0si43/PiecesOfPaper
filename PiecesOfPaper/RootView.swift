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
    @AppStorage("onboarding_v3.0.0") var didShowOnboarding = false

    private var useICloudButton: Alert.Button {
        .default(Text("Use iCloud"), action: viewModel.openSettingApp)
    }

    private var useDeviceButton: Alert.Button {
        .default(Text("Use device storage"), action: viewModel.switchDeviceStorage)
    }

    var body: some View {
        NavigationView {
            SideBarList()
        }
        .fullScreenCover(isPresented: $viewModel.showCanvas) {
            NavigationView {
                Canvas(viewModel: CanvasViewModel())
            }
        }
        .sheet(isPresented: $viewModel.showOnboarding) {
            Onboarding()
                .onAppear {
                    didShowOnboarding = true
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

            guard didShowOnboarding else {
                viewModel.showOnboarding = true
                return
            }

            guard !UserPreference().shouldGrantiCloud else {
                viewModel.iCloudDenying = true
                return
            }

            viewModel.showCanvas = true
        }
        .alert(isPresented: $viewModel.iCloudDenying) { () -> Alert in
            Alert(title: Text(viewModel.iCloudDeniedWarningMessage),
                  primaryButton: useICloudButton,
                  secondaryButton: useDeviceButton)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
