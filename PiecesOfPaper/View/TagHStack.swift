//
//  TagHStack.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct TagHStack: View {
    var tags = TagModel().tags
    var noteDocument: NoteDocument
    var isDeletable: Bool

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(tags, id: \.id) { tag in
                    if noteDocument.entity.tags.contains(tag.name) {
                        if isDeletable {
                            DeletableTag(entity: tag, noteDocument: noteDocument)
                        } else {
                            Tag(entity: tag)
                        }
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
