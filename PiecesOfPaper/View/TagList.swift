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
        List(tagListViewModel.tags) { tag in
            Text(tag.name)
                .padding(.all, 8)
                .background(tag.color.swiftUIColor)
                .cornerRadius(4)
        }
    }
}

struct TagList_Previews: PreviewProvider {
    static var previews: some View {
        TagList()
    }
}
