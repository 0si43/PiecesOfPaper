//
//  SettingViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/13.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

@Observable
final class SettingViewModel {
    private var userPreference: UserPreference
    var enablediCloud: Bool {
        didSet {
            userPreference.enablediCloud = enablediCloud
            FilePath.makeDirectoryIfNeeded()
        }
    }
    var enabledAutoSave: Bool {
        didSet {
            userPreference.enabledAutoSave = enabledAutoSave
        }
    }
    var enabledInfiniteScroll: Bool {
        didSet {
            userPreference.enabledInfiniteScroll = enabledInfiniteScroll
        }
    }

    init() {
        let pref = UserPreference()
        self.userPreference = pref
        self.enablediCloud = pref.enablediCloud
        self.enabledAutoSave = pref.enabledAutoSave
        self.enabledInfiniteScroll = pref.enabledInfiniteScroll
    }
}
