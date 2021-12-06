//
//  DeletableTagHStack.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct DeletableTagHStack: View {
    @EnvironmentObject var viewModel: TagListToNoteViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(viewModel.tagsToNote, id: \.id) { tag in
                    DeletableTag(entity: tag)
                        .onTapGesture {
                            viewModel.remove(tag: tag)
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
