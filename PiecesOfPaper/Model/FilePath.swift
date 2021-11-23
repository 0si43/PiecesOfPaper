//
//  FilePath.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/23.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

struct FilePath {
    static var iCloudURL: URL {
        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)!
            .appendingPathComponent("Documents")
        return url
    }
    
    static var documentDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first!
    }
    
    static var fileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ssSSSS"
        return dateFormatter.string(from: Date()) + ".drawing"
    }
}
