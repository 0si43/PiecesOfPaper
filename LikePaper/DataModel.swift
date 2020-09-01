//
//  DataModel.swift
//  LikeAPaper
//
//  Created by nakajima on 2020/05/01.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import Foundation
import PencilKit

struct DataModel: Codable {
    
    private(set) var drawings = [PKDrawing]()
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths.first!
        return documentsDirectory.appendingPathComponent("Like_a_Paper.data")
    }
    
    init() {
        let url = saveURL
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let decoder = PropertyListDecoder()
                let data = try Data(contentsOf: url)
                let dataModel = try decoder.decode(DataModel.self, from: data)
                self = dataModel
            } catch(let error) {
                print("Could not load data model: ", error.localizedDescription)
            }
        }
    }
    
    init(drawings: [PKDrawing]) {
        self.drawings = drawings
    }
    
    private func save() {
        let url = saveURL
        do {
            let encoder = PropertyListEncoder()
            let data = try encoder.encode(self)
            try data.write(to: url)
        } catch(let error) {
            print("Could not save data model: ", error.localizedDescription)
        }
    }
    
    func save(drawings: [PKDrawing]) {
        let model = DataModel(drawings: drawings)
        model.save()
    }
}
