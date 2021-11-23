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
    @State var noteDocument: NoteDocument?
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                SideBarList(isAppLaunch: $isAppLaunch)
            }
            
            .fullScreenCover(isPresented: $isShowCanvas)
            {
                NavigationView {
                    Canvas(noteDocument: noteDocument)
                }
            }
            .onAppear {
                guard isAppLaunch else { return }
                Router.shared.bind(isShowCanvas: $isShowCanvas, noteDocument: $noteDocument)
                Router.shared.openNewCanvas()
                isAppLaunch = false
            }
        }
    }
}
