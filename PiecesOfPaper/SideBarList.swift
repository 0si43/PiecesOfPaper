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
    let inboxNoteViewModel = NotesViewModel(targetDirectory: .inbox)
    let allNoteViewModel = NotesViewModel(targetDirectory: .all)
    let archivedNoteViewModel = NotesViewModel(targetDirectory: .archived)
    
    var body: some View {
        List {
            Section(header: Text("Folder")) {
                NavigationLink(destination: Notes(viewModel: inboxNoteViewModel), isActive: $isAppLaunch) {
                    Label("Inbox", systemImage: "tray")
                }
                NavigationLink(destination: Notes(viewModel: allNoteViewModel)) {
                    Label("All", systemImage: "note.text")
                }
                NavigationLink(destination: Notes(viewModel: archivedNoteViewModel)) {
                    Label("Archived", systemImage: "archivebox")
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
