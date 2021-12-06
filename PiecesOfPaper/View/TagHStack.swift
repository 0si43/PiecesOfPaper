//
//  TagHStack.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct TagHStack: View {
    @ObservedObject var viewModel: TagHStackViewModel
    var isDeletable: Bool

    init(noteDocument: NoteDocument, tags: [TagEntity], isDeletable: Bool) {
        self.viewModel = TagHStackViewModel(noteDocument: noteDocument, tags: tags)
        self.isDeletable = isDeletable
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(viewModel.tags, id: \.id) { tag in
                    if isDeletable {
                        DeletableTag(entity: tag)
                            .onTapGesture {
                                viewModel.remove(tag: tag)
                            }
                    } else {
                        Tag(entity: tag)
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
