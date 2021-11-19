//
//  PiecesOfPaperApp.swift
//  PiecesOfPaper
//
//  Created by nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

@main
struct PiecesOfPaperApp: App {
    @State var isAppLaunch = true
    @State var isShowCanvas = false
    @State var drawing = PKDrawing()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    Section(header: Text("Folder")) {
                        NavigationLink(destination: NotesGrid(), isActive: $isAppLaunch) {
                            Label("Home", systemImage: "tray")
                        }
                        NavigationLink(destination: EmptyView()) {
                            Label("All Notes", systemImage: "tray.full")
                        }
                        NavigationLink(destination: EmptyView()) {
                            Label("Archived", systemImage: "archivebox")
                        }
                    }
                    Section(header: Text("Setting")) {
                        NavigationLink(destination: EmptyView()) {
                            Label("Setting", systemImage: "gearshape")
                        }
                    }
                    Section(header: Text("About")) {
                        NavigationLink(destination: EmptyView()) {
                            Label("Github Repository", systemImage: "wrench")
                        }
                        NavigationLink(destination: EmptyView()) {
                            Label("Developer Site", systemImage: "wrench")
                        }
                    }
                }
                .listStyle(SidebarListStyle())
                .navigationTitle("Pieces of Paper")
            }
            
            .fullScreenCover(isPresented: $isShowCanvas)
            {
                NavigationView {
                    Canvas(drawing: drawing)
                }
            }
            .onAppear {
                if (isAppLaunch) {
                    Router.shared.setStateValue(isShowCanvas: $isShowCanvas)
                    Router.shared.toggleStateValue()
                    Router.shared.setDrawing(drawing: $drawing)
                    isAppLaunch = false
                }
            }
        }
    }
}
