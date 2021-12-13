//
//  SettingViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/13.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

final class SettingViewModel: ObservableObject {
    private let iCloudDisabledKey = "iCloud_disabled"
    private let autoSaveDisabledKey = "autosave_disabled"

    @Published var enablediCloud: Bool {
        didSet {
            UserDefaults.standard.set(!enablediCloud, forKey: iCloudDisabledKey)
        }
    }

    @Published var enabledAutoSave: Bool {
        didSet {
            UserDefaults.standard.set(!enabledAutoSave, forKey: autoSaveDisabledKey)
        }
    }

    init() {
        enablediCloud = !UserDefaults.standard.bool(forKey: iCloudDisabledKey)
        enabledAutoSave = !UserDefaults.standard.bool(forKey: autoSaveDisabledKey)
    }
}
