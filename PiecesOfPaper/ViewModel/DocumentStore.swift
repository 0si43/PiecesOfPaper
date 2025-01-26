//
//  DocumentStore.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2025/01/26.
//  Copyright © 2025 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

protocol DocumentStoreProtocol: AnyObject {
    var directory: DocumentStore.TargetDirectory { get }
    /// get file path array (iCloud or local storage)
    func getFileUrls() -> [URL]
    func open(fileUrl: URL) async throws -> NoteDocument
}

final class DocumentStore: DocumentStoreProtocol {
    private(set) var directory: TargetDirectory
    enum TargetDirectory: String {
        case inbox, archived
    }

    init(directory: TargetDirectory) {
        self.directory = directory
    }

    func getFileUrls() -> [URL] {
        switch directory {
        case .inbox:
            guard let inboxUrl = FilePath.inboxUrl,
                  var inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: inboxUrl.path) else { return [] }
            inboxFileNames = inboxFileNames.filter { $0.hasSuffix(".plist") }
            return inboxFileNames.map { inboxUrl.appendingPathComponent($0) }
        case .archived:
            guard let archivedUrl = FilePath.archivedUrl,
                  var archivedFileNames = try? FileManager.default.contentsOfDirectory(atPath: archivedUrl.path) else { return [] }
            archivedFileNames = archivedFileNames.filter { $0.hasSuffix(".plist") }
            return archivedFileNames.map { archivedUrl.appendingPathComponent($0) }
        }
    }

    @MainActor
    func open(fileUrl: URL) async throws -> NoteDocument {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            throw DocumentStoreError.fileNotExist(path: fileUrl.path)
        }
        let document = NoteDocument(fileURL: fileUrl)
        let isSuccess = await document.open()
        await document.close()
        if isSuccess {
            return document
        } else {
            throw DocumentStoreError.fileOpenFailed(path: fileUrl.path)
        }
    }
}

enum DocumentStoreError: Error {
    case fileNotExist(path: String)
    case fileOpenFailed(path: String)

    var localizedDescription: String {
        switch self {
        case .fileNotExist(let path):
            "File does not exist at \(path)."
        case .fileOpenFailed(let path):
            "Failed to open file at \(path)."
        }
    }
}
