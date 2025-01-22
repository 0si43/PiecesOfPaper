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
        .frame(minHeight: 40)
        .background(Color.gray.opacity(0.05))
        .onTapGesture { action() }
        
    }
}

 struct NoteListTagHStack_Previews: PreviewProvider {
     static var blue = TagEntity(id: UUID(), name: "blue", color: CodableUIColor(uiColor: .blue))
     static var yellow = TagEntity(id: UUID(), name: "yellow", color: CodableUIColor(uiColor: .yellow))
     static var red = TagEntity(id: UUID(), name: "red", color: CodableUIColor(uiColor: .red))
     static var previews: some View {
         NoteListTagHStack(tags: [blue, yellow, red], action: {})
    }
 }
