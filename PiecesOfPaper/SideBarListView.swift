//
//  SideBarListView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct SideBarListView: View {
    @State private var isActive = true
    @StateObject var inboxNoteViewModel = NotesViewModel(targetDirectory: .inbox)
    @StateObject var allNoteViewModel = NotesViewModel(targetDirectory: .all)
    @StateObject var archivedNoteViewModel = NotesViewModel(targetDirectory: .archived)

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationSplitView() {
                list
            } detail: {
                Notes(viewModel: inboxNoteViewModel)
            }
        } else {
            NavigationView {
                list
            }
        }
    }

    var list: some View {
        List {
            Section(header: Text("Folder")) {
                NavigationLink(destination: Notes(viewModel: inboxNoteViewModel),
                               isActive: $isActive) {
                    Label("Inbox", systemImage: "tray")
                }
                NavigationLink(destination: Notes(viewModel: allNoteViewModel)) {
                    Label("All", systemImage: "tray.full")
                }
                NavigationLink(destination: Notes(viewModel: archivedNoteViewModel)) {
                    Label("Trash", systemImage: "trash")
                }
            }
            Section(header: Text("Tag")) {
                NavigationLink(destination: TagList()) {
                    Label("Tag List", systemImage: "tag")
                }
            }
            Section(header: Text("Setting")) {
                NavigationLink(destination: SettingView()) {
                    Label("Setting", systemImage: "gearshape")
                }
            }
        }
        .navigationTitle("Pieces of Paper")
    }
}

struct SideBarListView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(TargetPreviewDevice.allCases) { deviceName in
            SideBarListView()
                .previewDevice(PreviewDevice(rawValue: deviceName.rawValue))
                .previewDisplayName(deviceName.rawValue)
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}
