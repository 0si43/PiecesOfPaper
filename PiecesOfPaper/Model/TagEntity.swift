//
//  TagEntity.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import SwiftUI

struct TagEntity: Codable, Identifiable, Equatable {
    var id = UUID()
    let name: String
    let color: CodableUIColor

    static func == (lhs: TagEntity, rhs: TagEntity) -> Bool {
        lhs.id == rhs.id
    }
}

struct CodableUIColor: Codable {
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0

    var swiftUIColor: Color {
        .init(red: red, green: green, blue: blue, opacity: 0.7)
    }

    init(uiColor: UIColor) {
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    }
}
