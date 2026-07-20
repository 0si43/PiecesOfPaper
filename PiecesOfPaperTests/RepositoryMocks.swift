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

        var url: URL {
            switch self {
            case .file1:
                URL(fileURLWithPath: "/path/to/2024-01-01-00-00-000000.pop")
            case .file2:
                URL(fileURLWithPath: "/path/to/2024-01-02-00-00-000000.pop")
            case .file3:
                URL(fileURLWithPath: "/path/to/2024-01-03-00-00-000000.pop")
            }
        }

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

    var notes: [NoteData]
    var failingUrls: Set<URL> = []
    var moveShouldThrow = false
    var duplicateShouldSucceed = true
    var enumeratedAttributes: [NoteFileAttributes] = TestFile.allCases.map(\.attributes)
    var savedFileAttributes: [URL: NoteFileAttributes] = [:]
    @MainActor private(set) var openCallCount = 0
    private(set) var cloudUpdateHandler: (@MainActor () -> Void)?

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
        if failingUrls.contains(fileUrl) {
            throw NoteRepositoryError.fileOpenFailed(path: fileUrl.path)
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

    func delete(fileUrl: URL) throws {}

    func move(fileUrl: URL, to directory: NoteDirectory) throws -> URL {
        if moveShouldThrow {
            throw NoteRepositoryError.directoryNotAvailable
        }
        return URL(fileURLWithPath: "/moved/\(fileUrl.lastPathComponent)")
    }

    func duplicate(_ note: NoteData, in directory: NoteDirectory,
                   completion: @escaping (NoteData?) -> Void) {
        guard duplicateShouldSucceed else {
            completion(nil)
            return
        }
        let newUrl = URL(fileURLWithPath: "/path/to/duplicated-\(note.fileURL.lastPathComponent)")
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
