//
//  PreviewDevice.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2022/02/10.
//  Copyright © 2022 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

enum TargetPreviewDevice: String, Identifiable, CaseIterable {
    var id: String { rawValue }

    case iPhone13Pro = "iPhone 13 Pro"
    case iPadPro5th = "iPad Pro (12.9-inch) (5th generation)"
}
