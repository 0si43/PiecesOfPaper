//
//  PiecesOfPaperApp.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct SideBarList: View {
    @Binding var isAppLaunch: Bool

    var body: some View {
        List {
            Section(header: Text("Folder")) {
                NavigationLink(destination: Notes(targetDirectory: .inbox), isActive: $isAppLaunch) {
                    Label("Inbox", systemImage: "tray")
                }
                NavigationLink(destination: Notes(targetDirectory: .all)) {
                    Label("All", systemImage: "note.text")
                }
                NavigationLink(destination: Notes(targetDirectory: .archived)) {
                    Label("Archived", systemImage: "archivebox")
                }
            }
            Section(header: Text("Tag")) {
                NavigationLink(destination: EmptyView()) {
                    Label("Tag", systemImage: "tag")
                }
            }
            Section(header: Text("Setting")) {
                NavigationLink(destination: EmptyView()) {
                    Label("Setting", systemImage: "gearshape")
                }
            }
            Section(header: Text("About")) {
                Link(destination: URL(string: "https://github.com/0si43/PiecesOfPaper")!) {
                    Label("Github Repository", systemImage: "wrench")
                }
                Link(destination: URL(string: "https://www.shetommy.com/")!) {
                    Label("Developer Site", systemImage: "wrench")
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Pieces of Paper")
    }
}
