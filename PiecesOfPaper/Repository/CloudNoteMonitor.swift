//
//  CloudNoteMonitor.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2026/07/19.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

struct CloudNoteItem: Equatable {
    let fileURL: URL
    let creationDate: Date?
    let contentModificationDate: Date?
}

/// Enumerates note files through the iCloud metadata index instead of the
/// local file system, so notes that exist in iCloud but are not downloaded
/// yet (placeholder `.icloud` files) are still visible.
@MainActor
final class CloudNoteMonitor {
    private let query = NSMetadataQuery()
    private var observers: [NSObjectProtocol] = []
    private var hasGathered = false
    private var gatherWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var noteItems: [CloudNoteItem] = []
    var onUpdate: (@MainActor () -> Void)?

    init() {
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K LIKE %@ OR %K LIKE %@",
                                      NSMetadataItemFSNameKey,
                                      "*." + FilePath.noteFileExtension,
                                      NSMetadataItemFSNameKey,
                                      "*." + FilePath.legacyNoteFileExtension)
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .NSMetadataQueryDidFinishGathering,
                                            object: query,
                                            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.finishGathering() }
        })
        observers.append(center.addObserver(forName: .NSMetadataQueryDidUpdate,
                                            object: query,
                                            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleUpdate() }
        })
        query.start()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// Waits for the initial gathering so that an in-progress query is never
    /// mistaken for an empty note list.
    func items() async -> [CloudNoteItem] {
        if !hasGathered {
            await withCheckedContinuation { gatherWaiters.append($0) }
        }
        return noteItems
    }

    func stop() {
        query.stop()
        resumeGatherWaiters()
    }

    private func finishGathering() {
        refreshResults()
        resumeGatherWaiters()
    }

    private func handleUpdate() {
        refreshResults()
        onUpdate?()
    }

    private func resumeGatherWaiters() {
        hasGathered = true
        gatherWaiters.forEach { $0.resume() }
        gatherWaiters.removeAll()
    }

    private func refreshResults() {
        query.disableUpdates()
        defer { query.enableUpdates() }
        noteItems = query.results.compactMap {
            guard let item = $0 as? NSMetadataItem,
                  let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL else { return nil }
            return CloudNoteItem(
                fileURL: url,
                creationDate: item.value(forAttribute: NSMetadataItemFSCreationDateKey) as? Date,
                contentModificationDate: item.value(forAttribute: NSMetadataItemFSContentChangeDateKey) as? Date
            )
        }
    }
}
