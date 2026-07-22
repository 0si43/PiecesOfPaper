import Foundation

protocol TagRepositoryProtocol {
    func fetchAll() -> [TagEntity]
    @discardableResult
    func saveAll(_ tags: [TagEntity]) -> Bool
}

/// Where the tag list file stands relative to iCloud download state.
enum TagListFileState {
    /// The real file exists locally and can be read.
    case downloaded
    /// Only the ".taglist.json.icloud" placeholder exists: the file lives in
    /// iCloud but has not been downloaded yet.
    case inCloudOnly
    /// Neither the file nor a placeholder exists locally.
    case absent

    static func check(for url: URL, fileManager: FileManager = .default) -> TagListFileState {
        if fileManager.fileExists(atPath: url.path) {
            return .downloaded
        }
        let placeholderUrl = url.deletingLastPathComponent()
            .appendingPathComponent("." + url.lastPathComponent + ".icloud")
        if fileManager.fileExists(atPath: placeholderUrl.path) {
            return .inCloudOnly
        }
        return .absent
    }
}

struct TagRepository: TagRepositoryProtocol {
    // Fixed ids so the in-memory defaults stay identical across launches:
    // notes reference tags by id, so ids regenerated per launch would detach
    // notes from their default tags.
    private var defaultTags = [
        TagEntity(id: UUID(uuidString: "1D9C7A80-1E5B-4A61-9F0A-6C39F1A0D001")!,
                  name: "💡idea", color: CodableUIColor(uiColor: .systemYellow)),
        TagEntity(id: UUID(uuidString: "1D9C7A80-1E5B-4A61-9F0A-6C39F1A0D002")!,
                  name: "🗒memo", color: CodableUIColor(uiColor: .systemBlue)),
        TagEntity(id: UUID(uuidString: "1D9C7A80-1E5B-4A61-9F0A-6C39F1A0D003")!,
                  name: "📓note", color: CodableUIColor(uiColor: .systemGreen)),
        TagEntity(id: UUID(uuidString: "1D9C7A80-1E5B-4A61-9F0A-6C39F1A0D004")!,
                  name: "🎨doodle", color: CodableUIColor(uiColor: .systemOrange))
    ]

    private let tagListFileUrl: URL?
    private let fileManager: FileManager

    init(tagListFileUrl: URL? = FilePath.tagListFileUrl, fileManager: FileManager = .default) {
        self.tagListFileUrl = tagListFileUrl
        self.fileManager = fileManager
    }

    // Never writes to disk: creating defaults while the iCloud copy is merely
    // undownloaded would sync them back and wipe the user's tag list (#199).
    // Defaults are persisted lazily by the first user edit through saveAll.
    func fetchAll() -> [TagEntity] {
        guard let tagListFileUrl else { return [] }
        syncFile(url: tagListFileUrl)

        switch TagListFileState.check(for: tagListFileUrl, fileManager: fileManager) {
        case .downloaded:
            return loadTags(from: tagListFileUrl)
        case .inCloudOnly:
            return []
        case .absent:
            return defaultTags
        }
    }

    @discardableResult
    func saveAll(_ tags: [TagEntity]) -> Bool {
        guard let tagListFileUrl else { return false }
        syncFile(url: tagListFileUrl)

        // Refuse to write over an undownloaded iCloud copy: the caller only
        // sees the transient empty list, so persisting it would overwrite the
        // real tag list once the write syncs.
        guard TagListFileState.check(for: tagListFileUrl, fileManager: fileManager) != .inCloudOnly else {
            return false
        }

        do {
            let libraryUrl = tagListFileUrl.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: libraryUrl.path) {
                try fileManager.createDirectory(at: libraryUrl, withIntermediateDirectories: true)
            }
            let data = try JSONEncoder().encode(tags)
            try data.write(to: tagListFileUrl, options: .atomic)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }

    private func loadTags(from url: URL) -> [TagEntity] {
        guard fileManager.fileExists(atPath: url.path),
              let content = fileManager.contents(atPath: url.path) else { return [] }

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
            try fileManager.startDownloadingUbiquitousItem(at: url)
        } catch {
            print(error.localizedDescription)
        }
    }
}
