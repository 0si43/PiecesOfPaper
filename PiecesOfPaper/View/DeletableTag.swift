//
//  DeletableTag.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct DeletableTag: View {
    var entity: TagEntity
    var noteDocument: NoteDocument

    var body: some View {
        HStack {
            Text(entity.name)
            Image(systemName: "multiply.square")
                .onTapGesture {
                    remove(tagName: entity.name, noteDocument: noteDocument)
                }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(entity.color.swiftUIColor)
        .cornerRadius(4)
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

// struct DeletableTag_Previews: PreviewProvider {
//    static var previews: some View {
//        DeletableTag(entity: TagEntity(name: "Memo", color: CodableUIColor(uiColor: UIColor.blue)))
//    }
// }
