//
//  TagHStack.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct TagHStack: View {
    var tags: [TagEntity]
    var action: ((TagEntity) -> Void)?
    var deletable = false

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

// struct TagHStack_Previews: PreviewProvider {
//    static var previews: some View {
//        TagHStack()
//    }
// }
