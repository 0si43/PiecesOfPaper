//
//  TagList.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct TagList: View {
    @Environment(TagStore.self) private var tagStore

    var body: some View {
        List {
            Section(footer: AddTagFooter(onSave: { tagStore.add($0) })) {
                ForEach(tagStore.tags, id: \.id) { tag in
                    Tag(entity: tag)
                }
                .onDelete { indexSet in
                    tagStore.remove(at: indexSet)
                }
            }
        }
        .onAppear {
            tagStore.reload()
        }
    }
}

#Preview {
    TagList()
        .environment(TagStore())
}
