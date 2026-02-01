//
//  TagHStack.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteListTagHStack: View {
    private(set) var tags: [TagEntity]
    private(set) var action: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.id) { tag in
                    Tag(entity: tag)
                }
            }
        }
        .frame(width: 250, height: 40)
        .contentShape(Rectangle())
        .onTapGesture { action() }
    }
}

#Preview {
    let blue = TagEntity(id: UUID(), name: "blue", color: CodableUIColor(uiColor: .blue))
    let yellow = TagEntity(id: UUID(), name: "yellow", color: CodableUIColor(uiColor: .yellow))
    let red = TagEntity(id: UUID(), name: "red", color: CodableUIColor(uiColor: .red))
    return NoteListTagHStack(tags: [blue, yellow, red], action: {})
}
