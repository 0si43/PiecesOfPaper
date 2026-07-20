//
//  NoteRepository.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2025/01/26.
//  Copyright © 2025 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit

enum NoteDirectory: String {
    case inbox, archived

    var url: URL? {
        switch self {
        case .inbox: FilePath.inboxUrl
        case .archived: FilePath.archivedUrl
        }
    }
}

struct NoteFileAttributes: Equatable {
    let fileURL: URL
    let creationDate: Date?
    let contentModificationDate: Date?
}

protocol NoteRepositoryProtocol: AnyObject {
    @MainActor func getFileUrls(directory: NoteDirectory) async -> [URL]
    @MainActor func getFileAttributes(directory: NoteDirectory) async -> [NoteFileAttributes]
    func fileAttributes(at fileUrl: URL) -> NoteFileAttributes?
    @MainActor func setCloudUpdateHandler(_ handler: @escaping @MainActor () -> Void)
    @MainActor func open(fileUrl: URL) async throws -> NoteData
    func save(_ entity: NoteEntity, to fileUrl: URL, completion: @escaping (Bool) -> Void)
    func delete(fileUrl: URL) throws
    func move(fileUrl: URL, to directory: NoteDirectory) throws -> URL
    func duplicate(_ note: NoteData, in directory: NoteDirectory,
                   completion: @escaping (NoteData?) -> Void)
}

final class NoteRepository: NoteRepositoryProtocol {
    @MainActor private var cloudMonitor: CloudNoteMonitor?
    @MainActor private var cloudUpdateHandler: (@MainActor () -> Void)?

    @MainActor
    func getFileUrls(directory: NoteDirectory) async -> [URL] {
        await getFileAttributes(directory: directory).map(\.fileURL)
    }

    @MainActor
    func getFileAttributes(directory: NoteDirectory) async -> [NoteFileAttributes] {
        guard let directoryUrl = directory.url else { return [] }
        LegacyNoteMigrator.migrate(in: directoryUrl)
        guard FilePath.isiCloudActive else {
            stopCloudMonitor()
            return localFileAttributes(in: directoryUrl)
        }
        let directoryPath = directoryUrl.resolvingSymlinksInPath().path
        var seen = Set<URL>()
        return await monitor().items()
            .filter { $0.fileURL.resolvingSymlinksInPath().deletingLastPathComponent().path == directoryPath }
            .map {
                NoteFileAttributes(fileURL: resolveMigratedUrl($0.fileURL),
                                   creationDate: $0.creationDate,
                                   contentModificationDate: $0.contentModificationDate)
            }
            .filter { seen.insert($0.fileURL).inserted }
    }

    // The metadata query and already-open notes can still hold a pre-rename
    // .plist URL after LegacyNoteMigrator moved the file. Point such URLs at
    // the renamed file so enumeration and saves never target a path that no
    // longer exists (a save to the stale path would fork the note).
    private func resolveMigratedUrl(_ fileUrl: URL) -> URL {
        guard fileUrl.pathExtension == FilePath.legacyNoteFileExtension,
              !FileManager.default.fileExists(atPath: fileUrl.path) else { return fileUrl }
        let migratedUrl = fileUrl.deletingPathExtension()
            .appendingPathExtension(FilePath.noteFileExtension)
        return FileManager.default.fileExists(atPath: migratedUrl.path) ? migratedUrl : fileUrl
    }

    @MainActor
    func setCloudUpdateHandler(_ handler: @escaping @MainActor () -> Void) {
        cloudUpdateHandler = handler
    }

    // Fallback when notes are stored in the local Documents directory,
    // where NSMetadataQuery finds nothing.
    private func localFileUrls(in directoryUrl: URL) -> [URL] {
        guard var fileNames = try? FileManager.default.contentsOfDirectory(atPath: directoryUrl.path) else { return [] }
        fileNames = fileNames.filter {
            $0.hasSuffix("." + FilePath.noteFileExtension)
                || $0.hasSuffix("." + FilePath.legacyNoteFileExtension)
        }
        return fileNames.map { directoryUrl.appendingPathComponent($0) }
    }

    func fileAttributes(at fileUrl: URL) -> NoteFileAttributes? {
        guard let values = try? fileUrl.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey]) else {
            return nil
        }
        return NoteFileAttributes(fileURL: fileUrl,
                                  creationDate: values.creationDate,
                                  contentModificationDate: values.contentModificationDate)
    }

    func localFileAttributes(in directoryUrl: URL) -> [NoteFileAttributes] {
        localFileUrls(in: directoryUrl).map { fileUrl in
            let values = try? fileUrl.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            return NoteFileAttributes(fileURL: fileUrl,
                                      creationDate: values?.creationDate,
                                      contentModificationDate: values?.contentModificationDate)
        }
    }

    @MainActor
    private func monitor() -> CloudNoteMonitor {
        if let cloudMonitor { return cloudMonitor }
        let monitor = CloudNoteMonitor()
        monitor.onUpdate = { [weak self] in self?.cloudUpdateHandler?() }
        cloudMonitor = monitor
        return monitor
    }

    @MainActor
    private func stopCloudMonitor() {
        cloudMonitor?.stop()
        cloudMonitor = nil
    }

    @MainActor
    func open(fileUrl: URL) async throws -> NoteData {
        // No fileExists guard: an undownloaded iCloud note has no local file yet.
        // Kick off the download and let UIDocument's coordinated read wait for it.
        try? FileManager.default.startDownloadingUbiquitousItem(at: fileUrl)
        let document = NoteDocument(fileURL: fileUrl)
        let isSuccess = await document.open()
        await document.close()
        if isSuccess {
            return NoteData(entity: document.entity, fileURL: fileUrl)
        } else {
            throw NoteRepositoryError.fileOpenFailed(path: fileUrl.path)
        }
    }

    func save(_ entity: NoteEntity, to fileUrl: URL, completion: @escaping (Bool) -> Void) {
        let targetUrl = resolveMigratedUrl(fileUrl)
        // The transient document lives until the completion handler fires,
        // which keeps its conflict observer active for the whole save.
        let document = NoteDocument(fileURL: targetUrl, entity: entity)
        let saveOperation: UIDocument.SaveOperation =
            FileManager.default.fileExists(atPath: targetUrl.path) ? .forOverwriting : .forCreating
        document.save(to: targetUrl, for: saveOperation, completionHandler: completion)
    }

    func delete(fileUrl: URL) throws {
        try FileManager.default.removeItem(at: fileUrl)
    }

    func move(fileUrl: URL, to directory: NoteDirectory) throws -> URL {
        guard let directoryUrl = directory.url else {
            throw NoteRepositoryError.directoryNotAvailable
        }
        let toUrl = directoryUrl.appendingPathComponent(fileUrl.lastPathComponent)
        try FileManager.default.moveItem(at: fileUrl, to: toUrl)
        return toUrl
    }

    func duplicate(_ note: NoteData, in directory: NoteDirectory,
                   completion: @escaping (NoteData?) -> Void) {
        guard let directoryUrl = directory.url else {
            completion(nil)
            return
        }
        let newUrl = directoryUrl.appendingPathComponent(FilePath.fileName)
        let entity = NoteEntity(drawing: note.entity.drawing)
        let newDocument = NoteDocument(fileURL: newUrl, entity: entity)
        newDocument.save(to: newUrl, for: .forCreating) { success in
            completion(success ? NoteData(entity: entity, fileURL: newUrl) : nil)
        }
    }
}

enum NoteRepositoryError: LocalizedError {
    case fileOpenFailed(path: String)
    case directoryNotAvailable

    var errorDescription: String? {
        switch self {
        case .fileOpenFailed(let path):
            "Failed to open file at \(path)."
        case .directoryNotAvailable:
            "Directory is not available."
        }
    }
}
