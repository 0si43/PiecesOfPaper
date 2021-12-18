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
    @State var isAppLaunch = true
    @State var isShowCanvas = false
    @State var isShowTagList = false
    @StateObject var canvasViewModel = CanvasViewModel()

    var body: some Scene {
        WindowGroup {
                NavigationView {
                    SideBarList(isAppLaunch: $isAppLaunch)
                }
                .fullScreenCover(isPresented: $isShowCanvas) {
                    NavigationView {
                        Canvas(viewModel: canvasViewModel)
                    }
                }
                .sheet(isPresented: $isShowTagList, onDismiss: {
                    TagListRouter.shared.documentForPass = nil
                }) {
                    TagListToNote()
                }
                .onAppear {
                    guard isAppLaunch else { return }
                    CanvasRouter.shared.bind(isShowCanvas: $isShowCanvas, noteDocument: $canvasViewModel.document)
                    CanvasRouter.shared.openNewCanvas()
                    // I thought this can work, but SwiftUI cannot pass the document data...
                    TagListRouter.shared.bind(isShowTagList: $isShowTagList)
                    DrawingsPlistConverter.convert()
                    isAppLaunch = false
                }
        }
    }
}
