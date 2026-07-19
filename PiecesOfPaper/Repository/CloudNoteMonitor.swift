//
//  CloudNoteMonitor.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2026/07/19.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

/// Enumerates note files through the iCloud metadata index instead of the
/// local file system, so notes that exist in iCloud but are not downloaded
/// yet (placeholder `.icloud` files) are still visible.
@MainActor
final class CloudNoteMonitor {
    private let query = NSMetadataQuery()
    private var observers: [NSObjectProtocol] = []
    private var hasGathered = false
    private var gatherWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var fileUrls: [URL] = []
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
    func urls() async -> [URL] {
        if !hasGathered {
            await withCheckedContinuation { gatherWaiters.append($0) }
        }
        return fileUrls
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
        fileUrls = query.results.compactMap {
            ($0 as? NSMetadataItem)?.value(forAttribute: NSMetadataItemURLKey) as? URL
        }
    }
}
