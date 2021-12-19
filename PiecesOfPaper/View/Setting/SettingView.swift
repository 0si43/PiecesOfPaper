//
//  SettingView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/13.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct SettingView: View {
    @ObservedObject var viewModel = SettingViewModel()

    var body: some View {
        List {
            Section(header: Text("Preference")) {
                Toggle(isOn: $viewModel.enablediCloud) {
                    Label("Enable iCloud", systemImage: viewModel.enablediCloud ? "icloud.fill" : "icloud")
                }
                Toggle(isOn: $viewModel.enabledAutoSave) {
                    Label("Auto Save", systemImage: "gearshape")
                }
                Toggle(isOn: $viewModel.enabledInfiniteScroll) {
                    Label("Infinite Scroll", systemImage: "scroll")
                }
            }
            Section(header: Text("Converter")) {
                Button(action: DrawingsPlistConverter.convert) {
                    Label("Convert drawings.plist", systemImage: "square.3.stack.3d")
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
        .foregroundColor(.primary)
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
