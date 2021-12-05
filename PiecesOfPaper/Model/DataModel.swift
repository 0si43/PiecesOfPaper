//
//  DataModel.swift
//  LikeAPaper
//
//  Created by Nakajima on 2020/05/01.
//  Copyright © 2020 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import PencilKit

struct DataModel: Codable {

    var drawings = [PKDrawing]()

    init() { }

    init(url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let decoder = PropertyListDecoder()
                let data = try Data(contentsOf: url)
                let dataModel = try decoder.decode(DataModel.self, from: data)
                self = dataModel
            } catch {
                print("Could not load data model: ", error.localizedDescription)
            }
        }
    }

    init(data: Data) {
        do {
            let decoder = PropertyListDecoder()
            let dataModel = try decoder.decode(DataModel.self, from: data)
            self = dataModel
        } catch {
            print("Could not load data model: ", error.localizedDescription)
        }
    }

    func data() -> Data? {
        let encoder = PropertyListEncoder()
        return try? encoder.encode(self)
    }
}
