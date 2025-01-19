//
//  RootView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2022/02/24.
//  Copyright © 2022 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showCanvasView = false

    var body: some View {
        SideBarListView()
        .fullScreenCover(isPresented: $showCanvasView) {
            NavigationStack {
                CanvasView(canvasViewModel: CanvasViewModel())
            }
        }
        .onAppear {
            appViewModel.hasDrawingPlist = DrawingsPlistConverter.hasDrawingsPlist
            DrawingsPlistConverter.convert()

            guard !UserPreference().shouldGrantiCloud else {
                appViewModel.iCloudDenying = true
                return
            }
            showCanvasView = true
        }
        .alert("", isPresented: $appViewModel.iCloudDenying) {
             Button("Use iCloud") {
                 appViewModel.openSettingApp()
             }
             Button("Use device storage") {
                 appViewModel.switchDeviceStorage()
             }
         } message: {
             Text(appViewModel.iCloudDeniedWarningMessage)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppViewModel())
    }
}
