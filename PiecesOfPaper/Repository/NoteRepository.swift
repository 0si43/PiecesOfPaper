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

protocol NoteRepositoryProtocol: AnyObject {
    func getFileUrls(directory: NoteDirectory) -> [URL]
    @MainActor func open(fileUrl: URL) async throws -> NoteData
    func save(_ entity: NoteEntity, to fileUrl: URL, completion: @escaping (Bool) -> Void)
    func delete(fileUrl: URL) throws
    func move(fileUrl: URL, to directory: NoteDirectory) throws -> URL
    func duplicate(_ note: NoteData, in directory: NoteDirectory,
                   completion: @escaping (NoteData?) -> Void)
}

final class NoteRepository: NoteRepositoryProtocol {
    func getFileUrls(directory: NoteDirectory) -> [URL] {
        guard let directoryUrl = directory.url,
              var fileNames = try? FileManager.default.contentsOfDirectory(atPath: directoryUrl.path) else { return [] }
        fileNames = fileNames.filter { $0.hasSuffix(".plist") }
        return fileNames.map { directoryUrl.appendingPathComponent($0) }
    }

    @MainActor
    func open(fileUrl: URL) async throws -> NoteData {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            throw NoteRepositoryError.fileNotExist(path: fileUrl.path)
        }
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
        // The transient document lives until the completion handler fires,
        // which keeps its conflict observer active for the whole save.
        let document = NoteDocument(fileURL: fileUrl, entity: entity)
        let saveOperation: UIDocument.SaveOperation =
            FileManager.default.fileExists(atPath: fileUrl.path) ? .forOverwriting : .forCreating
        document.save(to: fileUrl, for: saveOperation, completionHandler: completion)
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
    case fileNotExist(path: String)
    case fileOpenFailed(path: String)
    case directoryNotAvailable

    var errorDescription: String? {
        switch self {
        case .fileNotExist(let path):
            "File does not exist at \(path)."
        case .fileOpenFailed(let path):
            "Failed to open file at \(path)."
        case .directoryNotAvailable:
            "Directory is not available."
        }
    }
}
