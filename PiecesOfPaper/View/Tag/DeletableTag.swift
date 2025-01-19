//
//  DeletableTag.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct DeletableTag: View {
    private(set) var entity: TagEntity

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

 struct DeletableTag_Previews: PreviewProvider {
     static var entity = TagEntity(id: UUID(), name: "gray", color: CodableUIColor(uiColor: .gray))
    static var previews: some View {
        DeletableTag(entity: entity)
    }
 }
