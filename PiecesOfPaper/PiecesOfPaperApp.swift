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
    @StateObject var appViewModel = AppViewModel()
    @StateObject var canvasViewModel = CanvasViewModel()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
                .environmentObject(canvasViewModel)
        }
    }
}
