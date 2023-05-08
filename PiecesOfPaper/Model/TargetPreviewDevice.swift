//
//  TargetPreviewDevice.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2022/02/10.
//  Copyright © 2022 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

enum TargetPreviewDevice: String, Identifiable, CaseIterable {
    var id: String { rawValue }

    case iPhone14Pro = "iPhone 14 Pro"
    case iPadPro6th = "iPad Pro (12.9-inch) (6th generation)"
}
