//
//  TagList.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct TagList: View {
    @ObservedObject var tagListViewModel = TagListViewModel()

    var body: some View {
        List {
            ForEach(tagListViewModel.tags, id: \.id) { tag in
                Tag(entity: tag)
            }
        }
    }
}

struct TagList_Previews: PreviewProvider {
    static var previews: some View {
        TagList()
    }
}
