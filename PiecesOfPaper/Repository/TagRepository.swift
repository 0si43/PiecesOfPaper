//
//  TagRepository.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

protocol TagRepositoryProtocol {
    func fetchAll() -> [TagEntity]
    func saveAll(_ tags: [TagEntity])
}

struct TagRepository: TagRepositoryProtocol {
    private var defaultTags = [
        TagEntity(name: "💡idea", color: CodableUIColor(uiColor: .systemYellow)),
        TagEntity(name: "🗒memo", color: CodableUIColor(uiColor: .systemBlue)),
        TagEntity(name: "📓note", color: CodableUIColor(uiColor: .systemGreen)),
        TagEntity(name: "🎨doodle", color: CodableUIColor(uiColor: .systemOrange))
    ]

    func fetchAll() -> [TagEntity] {
        guard let tagListFileUrl = FilePath.tagListFileUrl else { return [] }
        syncFile(url: tagListFileUrl)

        if !FileManager.default.fileExists(atPath: tagListFileUrl.path) {
            makeFileIfNeeded()
            return defaultTags
        } else {
            return loadTags(from: tagListFileUrl)
        }
    }

    func saveAll(_ tags: [TagEntity]) {
        guard let tagListFileUrl = FilePath.tagListFileUrl else { return }
        syncFile(url: tagListFileUrl)

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(tags) else { return }
        do {
            try data.write(to: tagListFileUrl)
        } catch {
            print(error.localizedDescription)
        }
    }

    private func loadTags(from url: URL) -> [TagEntity] {
        guard FileManager.default.fileExists(atPath: url.path),
              let content = FileManager.default.contents(atPath: url.path) else { return [] }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode([TagEntity].self, from: content)
        } catch {
            print("Data file format error: ", error.localizedDescription)
            return []
        }
    }

    private func syncFile(url: URL) {
        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: url)
        } catch {
            print(error.localizedDescription)
        }
    }

    private func makeFileIfNeeded() {
        guard let libraryUrl = FilePath.libraryUrl else { return }

        if !FileManager.default.fileExists(atPath: libraryUrl.path) {
            try? FileManager.default.createDirectory(at: libraryUrl, withIntermediateDirectories: false)
        }

        saveAll(defaultTags)
    }
}
