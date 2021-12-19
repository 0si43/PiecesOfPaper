//
//  SettingViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/13.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

final class SettingViewModel: ObservableObject {
    var userPreference = UserPreference()

    @Published var enablediCloud: Bool {
        didSet {
            userPreference.enablediCloud = enablediCloud
            FilePath.makeDirectoryIfNeeded()
        }
    }

    @Published var enabledAutoSave: Bool {
        didSet {
            userPreference.enabledAutoSave = enabledAutoSave
        }
    }

    @Published var enabledInfiniteScroll: Bool {
        didSet {
            userPreference.enabledInfiniteScroll = enabledInfiniteScroll
        }
    }

    init() {
        enablediCloud = userPreference.enablediCloud
        enabledAutoSave = userPreference.enabledAutoSave
        enabledInfiniteScroll = userPreference.enabledInfiniteScroll
    }
}
