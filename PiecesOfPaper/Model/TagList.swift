//
//  TagList.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

struct TagList {
    var tags: [TagEntity]

    var defaultTags = [
        TagEntity(name: "idea", color: CodableUIColor(uiColor: .systemYellow)),
        TagEntity(name: "memo", color: CodableUIColor(uiColor: .systemBlue)),
        TagEntity(name: "note", color: CodableUIColor(uiColor: .systemGreen)),
        TagEntity(name: "doodle", color: CodableUIColor(uiColor: .systemOrange))
    ]

    mutating func save() {
        tags = defaultTags
        let dir = FilePath.applicationSupportDir
        let encoder = PropertyListEncoder()
        let data = (try? encoder.encode(tags)) ?? Data()
        do {
            try data.write(to: dir)
        } catch {
            print(error.localizedDescription)
        }
    }
}
