//
//  SettingView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/13.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct SettingView: View {
    @State private var viewModel = SettingViewModel()
    private let repositoryUrl = URL(string: "https://github.com/0si43/PiecesOfPaper")
    private let developerSiteUrl = URL(string: "https://www.shetommy.com/")

    var body: some View {
        List {
            Section(header: Text("Preference")) {
                Toggle(isOn: $viewModel.enablediCloud) {
                    Label("Enable iCloud", systemImage: "icloud")
                }
                Toggle(isOn: $viewModel.enabledAutoSave) {
                    Label("Auto Save", systemImage: "gearshape")
                }
                Toggle(isOn: $viewModel.enabledInfiniteScroll) {
                    Label("Infinite Scroll", systemImage: "scroll")
                }
            }
            Section(header: Text("About")) {
                if let url = repositoryUrl {
                    Link(destination: url) {
                        Label("Github Repository", systemImage: "ellipsis.curlybraces")
                    }
                }

                if let url = developerSiteUrl {
                    Link(destination: url) {
                        Label("Developer Site", systemImage: "wrench")
                    }
                }
            }
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    SettingView()
}
