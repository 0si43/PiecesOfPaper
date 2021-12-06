//
//  TagListToNote.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct TagListToNote: View {
    @ObservedObject var tagListViewModel = TagListViewModel()

    var body: some View {
        List {
            if let noteDocument = TagListRouter.shared.documentForPass {
                TagHStack(noteDocument: noteDocument)
                Section(header: Text("Select tag which you want to add")) {
                    ForEach(tagListViewModel.tags, id: \.id) { tag in
                        if !noteDocument.entity.tags.contains(tag.name) {
                            Tag(entity: tag)
                                .onTapGesture {
                                    add(tagName: tag.name, noteDocument: noteDocument)
                                }
                        }
                    }
                }
            }
        }
    }

    func add(tagName: String, noteDocument: NoteDocument) {
        noteDocument.entity.tags.append(tagName)
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

struct TagListToNote_Previews: PreviewProvider {
    static var previews: some View {
        TagListToNote()
    }
}
