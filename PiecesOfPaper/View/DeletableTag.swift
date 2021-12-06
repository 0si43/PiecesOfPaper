//
//  DeletableTag.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct DeletableTag: View {
    var entity: TagEntity

    var body: some View {
        HStack {
            Text(entity.name)
            Image(systemName: "multiply.square")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(entity.color.swiftUIColor)
        .cornerRadius(4)
    }
}

// struct DeletableTag_Previews: PreviewProvider {
//    static var previews: some View {
//        DeletableTag(entity: TagEntity(name: "Memo", color: CodableUIColor(uiColor: UIColor.blue)))
//    }
// }
