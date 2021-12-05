//
//  TagListViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

final class TagListViewModel: ObservableObject {
    var tags = [TagEntity]()

    private var defaultTags = [
        TagEntity(name: "idea", color: CodableUIColor(uiColor: .systemYellow)),
        TagEntity(name: "memo", color: CodableUIColor(uiColor: .systemBlue)),
        TagEntity(name: "note", color: CodableUIColor(uiColor: .systemGreen)),
        TagEntity(name: "doodle", color: CodableUIColor(uiColor: .systemOrange))
    ]

    init() {
        guard let tagListFileName = FilePath.tagListFileName else { return }
        if !FileManager.default.fileExists(atPath: tagListFileName.path) {
            makeFileIfNeeded()
        } else {
            load()
        }
    }

    private func makeFileIfNeeded() {
        guard let libraryUrl = FilePath.iCloudLibraryUrl else { return }

        if !FileManager.default.fileExists(atPath: libraryUrl.path) {
            try? FileManager.default.createDirectory(at: libraryUrl, withIntermediateDirectories: false)
        }

        tags = defaultTags
        save()
    }

    func save() {
        guard let iCloudLibraryUrl = FilePath.iCloudLibraryUrl else { return }
        let url = iCloudLibraryUrl.appendingPathComponent("taglist.plist")
        let encoder = PropertyListEncoder()
        let data = (try? encoder.encode(tags)) ?? Data()
        do {
            try data.write(to: url)
        } catch {
            print(error.localizedDescription)
        }
    }

    func load() {
        guard let iCloudLibraryUrl = FilePath.iCloudLibraryUrl else { return }
        let url = iCloudLibraryUrl.appendingPathComponent("taglist.plist")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let content = FileManager.default.contents(atPath: url.path)
        guard let content = content else { return }
        let decoder = PropertyListDecoder()
        do {
            tags = try decoder.decode([TagEntity].self, from: content)
        } catch {
            print("Data file format error: ", error.localizedDescription)
        }
    }
}
