//
//  Document.swift
//  LikePaper
//
//  Created by Nakajima on 2020/09/29.
//  Copyright © 2020 Tsuyoshi Nakajima. All rights reserved.
//

import UIKit
import PencilKit

final class Document: UIDocument {
    var dataModel = DataModel()

    override func contents(forType typeName: String) throws -> Any {
        dataModel.data() ?? Data()
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else { return }
        dataModel = DataModel(data: data)
    }
}
