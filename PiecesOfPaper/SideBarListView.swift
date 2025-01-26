//
//  SideBarListView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct SideBarListView: View {
    @StateObject private var inboxNoteViewModel = NoteViewModel(targetDirectory: .inbox)
    @StateObject private var archivedNoteViewModel = NoteViewModel(targetDirectory: .archived)
    @State private var selection: Page? = .inbox
    private enum Page: String, CaseIterable {
        case inbox, trash
        case tag
        case setting

        var label: String {
            switch self {
            case .inbox: "Inbox"
            case .trash: "Trash"
            case .tag: "Tag List"
            case .setting: "Setting"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sideBarList
        } detail: {
            switch selection {
            case .inbox:
                NoteListParentView(viewModel: inboxNoteViewModel)
            case .trash:
                NoteListParentView(viewModel: archivedNoteViewModel)
            case .tag:
                TagList()
            case .setting:
                SettingView()
            default:
                Text("Unknown page")
            }
        }
    }

    private var sideBarList: some View {
        List(selection: $selection) {
            Section(header: Text("Folders")) {
                NavigationLink(value: Page.inbox) {
                    Label(Page.inbox.label, systemImage: "tray")
                }

                NavigationLink(value: Page.trash) {
                    Label(Page.trash.label, systemImage: "trash")
                }
            }
            Section(header: Text("Tag")) {
                NavigationLink(value: Page.tag) {
                    Label(Page.tag.label, systemImage: "tag")
                }
            }
            Section(header: Text("Setting")) {
                NavigationLink(value: Page.setting) {
                    Label(Page.setting.label, systemImage: "gearshape")
                }
            }
        }
        .navigationTitle("Pieces of Paper")
    }
}

struct SideBarListView_Previews: PreviewProvider {
    static var previews: some View {
        SideBarListView()
    }
}
