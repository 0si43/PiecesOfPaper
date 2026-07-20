//
//  RepositoryMocks.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2026/07/20.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit
@testable import Pieces_of_Paper

final class NoteRepositoryMock: NoteRepositoryProtocol {
    enum TestFile: CaseIterable {
        case file1, file2, file3

        // Fixture URLs live under the inbox directory so applySaved treats
        // them as managed notes (foreign URLs are intentionally never listed)
        // swiftlint:disable force_unwrapping
        var url: URL {
            switch self {
            case .file1:
                FilePath.inboxUrl!.appendingPathComponent("2024-01-01-00-00-000000.pop")
            case .file2:
                FilePath.inboxUrl!.appendingPathComponent("2024-01-02-00-00-000000.pop")
            case .file3:
                FilePath.inboxUrl!.appendingPathComponent("2024-01-03-00-00-000000.pop")
            }
        }
        // swiftlint:enable force_unwrapping

        // Reverse of the filename (created) order so tests can tell the sort keys apart
        var contentModificationDate: Date {
            switch self {
            case .file1:
                Date(timeIntervalSince1970: 3_000)
            case .file2:
                Date(timeIntervalSince1970: 2_000)
            case .file3:
                Date(timeIntervalSince1970: 1_000)
            }
        }

        var attributes: NoteFileAttributes {
            NoteFileAttributes(fileURL: url, creationDate: nil, contentModificationDate: contentModificationDate)
        }
    }

    // Outside TestFile: getFileAttributes returns TestFile.allCases, and these
    // URLs must never appear in a directory listing
    static let externalUrl = URL(fileURLWithPath: "/external/file1.pop")
    static let externalUrl2 = URL(fileURLWithPath: "/external/file2.pop")

    var notes: [NoteData]
    var failingUrls: Set<URL> = []
    var moveShouldThrow = false
    var deleteShouldThrow = false
    @MainActor private(set) var deletedUrls: [URL] = []
    @MainActor private(set) var movedUrls: [URL] = []
    @MainActor var suspendFileOperations = false
    @MainActor private var pendingFileOperations: [CheckedContinuation<Void, Never>] = []
    @MainActor var hasPendingFileOperation: Bool { !pendingFileOperations.isEmpty }
    var duplicateShouldSucceed = true
    var enumeratedAttributes: [NoteFileAttributes] = TestFile.allCases.map(\.attributes)
    var savedFileAttributes: [URL: NoteFileAttributes] = [:]
    @MainActor private(set) var openCallCount = 0
    @MainActor var suspendOpens = false
    @MainActor private var pendingOpens: [CheckedContinuation<Void, Never>] = []
    @MainActor var hasPendingOpen: Bool { !pendingOpens.isEmpty }
    private(set) var cloudUpdateHandler: (@MainActor () -> Void)?

    @MainActor
    func resumePendingOpens() {
        pendingOpens.forEach { $0.resume() }
        pendingOpens.removeAll()
    }

    @MainActor
    func resumePendingFileOperations() {
        pendingFileOperations.forEach { $0.resume() }
        pendingFileOperations.removeAll()
    }

    init(notes: [NoteData]) {
        self.notes = notes
    }

    @MainActor
    func getFileAttributes(directory: NoteDirectory) async -> [NoteFileAttributes] {
        directory == .inbox ? enumeratedAttributes : []
    }

    func fileAttributes(at fileUrl: URL) -> NoteFileAttributes? {
        savedFileAttributes[fileUrl]
    }

    @MainActor
    func setCloudUpdateHandler(_ handler: @escaping @MainActor () -> Void) {
        cloudUpdateHandler = handler
    }

    @MainActor
    func open(fileUrl: URL) async throws -> NoteData {
        openCallCount += 1
        // Suspend once so overlapping loads actually overlap on the main actor
        await Task.yield()
        if suspendOpens {
            await withCheckedContinuation { pendingOpens.append($0) }
        }
        if failingUrls.contains(fileUrl) {
            throw NoteRepositoryError.fileOpenFailed(path: fileUrl.path)
        }
        if fileUrl == Self.externalUrl {
            return notes[0]
        }
        if fileUrl == Self.externalUrl2 {
            return notes[1]
        }
        guard let note = notes.first(where: { $0.fileURL == fileUrl }) else {
            fatalError()
        }
        return note
    }

    var saveShouldSucceed = true
    private(set) var saveCallCount = 0
    func save(_ entity: NoteEntity, to fileUrl: URL, completion: @escaping (Bool) -> Void) {
        saveCallCount += 1
        completion(saveShouldSucceed)
    }

    @MainActor
    func delete(fileUrl: URL) async throws {
        await suspendFileOperationIfNeeded()
        if deleteShouldThrow {
            throw NoteRepositoryError.directoryNotAvailable
        }
        deletedUrls.append(fileUrl)
    }

    @MainActor
    func move(fileUrl: URL, to directory: NoteDirectory) async throws -> URL {
        await suspendFileOperationIfNeeded()
        if moveShouldThrow {
            throw NoteRepositoryError.directoryNotAvailable
        }
        movedUrls.append(fileUrl)
        return URL(fileURLWithPath: "/moved/\(fileUrl.lastPathComponent)")
    }

    @MainActor
    private func suspendFileOperationIfNeeded() async {
        // Suspend once so the store's optimistic index update is observable
        // before the operation lands
        await Task.yield()
        if suspendFileOperations {
            await withCheckedContinuation { pendingFileOperations.append($0) }
        }
    }

    func duplicate(_ note: NoteData, in directory: NoteDirectory,
                   completion: @escaping (NoteData?) -> Void) {
        guard duplicateShouldSucceed,
              let newUrl = FilePath.inboxUrl?
                  .appendingPathComponent("duplicated-\(note.fileURL.lastPathComponent)") else {
            completion(nil)
            return
        }
        completion(NoteData(entity: NoteEntity(drawing: note.entity.drawing), fileURL: newUrl))
    }
}

final class PreferenceRepositoryMock: PreferenceRepositoryProtocol {
    var enablediCloud = false
    var enabledAutoSave = true
    var enabledInfiniteScroll = true
    var listOrders: [String: ListOrder] = [:]
    private(set) var setEnablediCloudCalls: [Bool] = []
    private(set) var setEnabledAutoSaveCalls: [Bool] = []
    private(set) var setEnabledInfiniteScrollCalls: [Bool] = []
    private(set) var setListOrderCalls: [(directoryName: String, listOrder: ListOrder)] = []

    func getEnablediCloud() -> Bool { enablediCloud }

    func setEnablediCloud(_ value: Bool) {
        enablediCloud = value
        setEnablediCloudCalls.append(value)
    }

    func getEnabledAutoSave() -> Bool { enabledAutoSave }

    func setEnabledAutoSave(_ value: Bool) {
        enabledAutoSave = value
        setEnabledAutoSaveCalls.append(value)
    }

    func getEnabledInfiniteScroll() -> Bool { enabledInfiniteScroll }

    func setEnabledInfiniteScroll(_ value: Bool) {
        enabledInfiniteScroll = value
        setEnabledInfiniteScrollCalls.append(value)
    }

    func getListOrder(directoryName: String) -> ListOrder {
        listOrders[directoryName] ?? ListOrder()
    }

    func setListOrder(directoryName: String, listOrder: ListOrder) {
        listOrders[directoryName] = listOrder
        setListOrderCalls.append((directoryName, listOrder))
    }
}
