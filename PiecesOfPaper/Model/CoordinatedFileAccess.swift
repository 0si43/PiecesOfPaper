//
//  CoordinatedFileAccess.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2026/07/20.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

/// Runs file operations under NSFileCoordinator so they do not race the iCloud
/// sync daemon or another process holding the same file.
enum CoordinatedFileAccess {
    // The intent-based API grants access asynchronously, so waiting for other
    // participants never occupies this queue or the caller's thread. Only the
    // accessor bodies run here, and they are short FileManager calls.
    private static let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    static func read<T>(at url: URL, _ body: @escaping (URL) throws -> T) async throws -> T {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        let intent = NSFileAccessIntent.readingIntent(with: url)
        return try await coordinate([intent], with: coordinator) {
            try body(intent.url)
        }
    }

    static func write<T>(at url: URL,
                         options: NSFileCoordinator.WritingOptions,
                         _ body: @escaping (URL) throws -> T) async throws -> T {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        let intent = NSFileAccessIntent.writingIntent(with: url, options: options)
        return try await coordinate([intent], with: coordinator) {
            try body(intent.url)
        }
    }

    @discardableResult
    static func move(from sourceUrl: URL, to destinationUrl: URL) async throws -> URL {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        let source = NSFileAccessIntent.writingIntent(with: sourceUrl, options: .forMoving)
        let destination = NSFileAccessIntent.writingIntent(with: destinationUrl, options: .forReplacing)
        return try await coordinate([source, destination], with: coordinator) {
            // Without the willMove/didMove pair the other participants see a
            // deletion followed by an unrelated new file instead of a move.
            coordinator.item(at: source.url, willMoveTo: destination.url)
            try FileManager.default.moveItem(at: source.url, to: destination.url)
            coordinator.item(at: source.url, didMoveTo: destination.url)
            return destination.url
        }
    }

    private static func coordinate<T>(_ intents: [NSFileAccessIntent],
                                      with coordinator: NSFileCoordinator,
                                      body: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            coordinator.coordinate(with: intents, queue: queue) { coordinationError in
                if let coordinationError {
                    continuation.resume(throwing: coordinationError)
                    return
                }
                do {
                    continuation.resume(returning: try body())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
