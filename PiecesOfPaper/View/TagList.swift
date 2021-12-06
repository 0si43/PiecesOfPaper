//
//  TagList.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct TagList: View {
    @ObservedObject var viewModel = TagListViewModel()

    var body: some View {
        List {
            ForEach(viewModel.tags, id: \.id) { tag in
                Tag(entity: tag)
            }
            .onDelete { indexSet in
                viewModel.remove(indexSet: indexSet)
            }
        }
    }
}

struct TagList_Previews: PreviewProvider {
    static var previews: some View {
        TagList()
    }
}
