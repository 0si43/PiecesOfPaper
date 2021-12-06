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

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(tags, id: \.id) { tag in
                    if noteDocument.entity.tags.contains(tag.name) {
                        Tag(entity: tag)
                            .onTapGesture {
                                remove(tagName: tag.name, noteDocument: noteDocument)
                            }
                    }
                }
            }
        }
        .frame(minHeight: 60)
    }

    func remove(tagName: String, noteDocument: NoteDocument) {
        noteDocument.entity.tags = noteDocument.entity.tags.filter { $0 != tagName }
        save(noteDocument: noteDocument)
    }

    private func save(noteDocument: NoteDocument) {
        noteDocument.save(to: noteDocument.fileURL, for: .forOverwriting) { success in
            if !success {
                print("save failed")
            }
        }
    }
}

// struct TagHStack_Previews: PreviewProvider {
//    static var previews: some View {
//        TagHStack()
//    }
// }
