//
//  FilePath.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/23.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

struct FilePath {
    static var savingUrl: URL? {
        UserPreference().enablediCloud ? iCloudUrl : documentDirectoryUrl
    }

    static var iCloudUrl: URL? {
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        return url.appendingPathComponent("Documents")
    }

    static var documentDirectoryUrl: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    // avoided to conflict the name of "Documents/Inbox/"
    static var inboxUrl: URL? {
        savingUrl?.appendingPathComponent("InboxFolder")
    }

    static var archivedUrl: URL? {
        savingUrl?.appendingPathComponent("Archived")
    }

    static var libraryUrl: URL? {
        savingUrl?.appendingPathComponent(".Library")
    }

    static var fileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ssSSSS"
        return dateFormatter.string(from: Date()) + ".plist"
    }

    static var tagListFileUrl: URL? {
        libraryUrl?.appendingPathComponent("taglist.plist")
    }

    static func makeDirectoryIfNeeded() {
        guard let inboxUrl = FilePath.inboxUrl, let archivedUrl = FilePath.archivedUrl else { return }
        if !FileManager.default.fileExists(atPath: inboxUrl.path) {
            try? FileManager.default.createDirectory(at: inboxUrl, withIntermediateDirectories: false)
        }

        if !FileManager.default.fileExists(atPath: archivedUrl.path) {
            try? FileManager.default.createDirectory(at: archivedUrl, withIntermediateDirectories: false)
        }
    }
}
