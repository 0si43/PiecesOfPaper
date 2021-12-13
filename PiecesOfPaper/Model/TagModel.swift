//
//  TagModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

struct TagModel {
    var tags: [TagEntity] {
        guard let libraryUrl = FilePath.libraryUrl?.appendingPathComponent("taglist.plist"),
                FileManager.default.fileExists(atPath: libraryUrl.path),
              let content = FileManager.default.contents(atPath: libraryUrl.path) else { return [] }
        let decoder = PropertyListDecoder()
        do {
            return try decoder.decode([TagEntity].self, from: content)
        } catch {
            print("Data file format error: ", error.localizedDescription)
            return []
        }
    }

    private var defaultTags = [
        TagEntity(name: "💡idea", color: CodableUIColor(uiColor: .systemYellow)),
        TagEntity(name: "🗒memo", color: CodableUIColor(uiColor: .systemBlue)),
        TagEntity(name: "📓note", color: CodableUIColor(uiColor: .systemGreen)),
        TagEntity(name: "🎨doodle", color: CodableUIColor(uiColor: .systemOrange))
    ]

    func fetch() -> [TagEntity] {
        guard let tagListFileName = FilePath.tagListFileName else { return [] }
        if !FileManager.default.fileExists(atPath: tagListFileName.path) {
            makeFileIfNeeded()
            return defaultTags
        } else {
            return tags
        }
    }

    private func makeFileIfNeeded() {
        guard let libraryUrl = FilePath.libraryUrl else { return }

        if !FileManager.default.fileExists(atPath: libraryUrl.path) {
            try? FileManager.default.createDirectory(at: libraryUrl, withIntermediateDirectories: false)
        }

        save(tags: defaultTags)
    }

    func save(tags: [TagEntity]) {
        guard let libraryUrl = FilePath.libraryUrl else { return }
        let url = libraryUrl.appendingPathComponent("taglist.plist")
        let encoder = PropertyListEncoder()
        let data = (try? encoder.encode(tags)) ?? Data()
        do {
            try data.write(to: url)
        } catch {
            print(error.localizedDescription)
        }
    }
}
