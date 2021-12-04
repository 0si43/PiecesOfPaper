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
    
    static var documentDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first!
    }
    
    static var fileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ssSSSS"
        return dateFormatter.string(from: Date()) + ".pkdrawing"
    }
}
