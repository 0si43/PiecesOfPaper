//
//  FilePath.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/23.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

struct FilePath {
    static var iCloudUrl: URL? {
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        return url.appendingPathComponent("Documents")
    }

    static var iCloudInboxUrl: URL? {
        iCloudUrl?.appendingPathComponent("Inbox")
    }

    static var iCloudArchivedUrl: URL? {
        iCloudUrl?.appendingPathComponent("Archived")
    }

    static var iCloudLibraryUrl: URL? {
        iCloudUrl?.appendingPathComponent(".Library")
    }

    static var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var fileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ssSSSS"
        return dateFormatter.string(from: Date()) + ".plist"
    }
}
