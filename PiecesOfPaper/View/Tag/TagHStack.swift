//
//  TagHStack.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct TagHStack: View {
    private(set) var tags: [TagEntity]
    private(set) var action: ((TagEntity) -> Void)?
    private(set) var deletable = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.id) { tag in
                    if deletable {
                        DeletableTag(entity: tag)
                            .onTapGesture { action?(tag) }
                    } else {
                        Tag(entity: tag)
                            .onTapGesture { action?(tag) }
                    }

                }
            }
        }
        .frame(minHeight: 60)
    }
}

 struct TagHStack_Previews: PreviewProvider {
     static var blue = TagEntity(id: UUID(), name: "blue", color: CodableUIColor(uiColor: .blue))
     static var yellow = TagEntity(id: UUID(), name: "yellow", color: CodableUIColor(uiColor: .yellow))
     static var red = TagEntity(id: UUID(), name: "red", color: CodableUIColor(uiColor: .red))
     static var previews: some View {
        TagHStack(tags: [blue, yellow, red])
    }
 }
