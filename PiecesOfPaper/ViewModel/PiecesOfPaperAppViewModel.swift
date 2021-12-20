//
//  PiecesOfPaperAppViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/20.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit

final class PiecesOfPaperAppViewModel: ObservableObject {
    @Published var isShowCanvas = false
    @Published var isShowTagList = false
    @Published var iCloudDenying = false
    var hasDrawingPlist = false
    let iCloudDeniedWarningMessage = "The app could not access your iCloud Drive. You should change setting"

    func openSettingApp() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func switchDeviceStorage() {
        var userPreference = UserPreference()
        userPreference.enablediCloud = false
    }
}
