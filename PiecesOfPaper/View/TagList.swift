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
    @Environment(\.editMode) var editMode

    var body: some View {
        List {
            ForEach(tagListViewModel.tags, id: \.id) { tag in
                Text(tag.name)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(tag.color.swiftUIColor)
                    .cornerRadius(4)
                    .onTapGesture {
                        guard let noteDocument = TagListRouter.shared.documentForPass else { return }
                        if noteDocument.entity.tags.contains(tag.name) {
                            noteDocument.entity.tags = Array(noteDocument.entity.tags.drop { $0 == tag.name })
                        } else {
                            noteDocument.entity.tags.append(tag.name)
                        }
                        noteDocument.save(to: noteDocument.fileURL, for: .forOverwriting) { success in
                            if !success {
                                print("save failed")
                            }
                        }
                    }
            }
            .onDelete { _ in print("delete") }
        }
        .navigationBarItems(trailing: EditButton())
    }

    private func addTag(to document: NoteDocument) {

    }
}

struct TagList_Previews: PreviewProvider {
    static var previews: some View {
        TagList()
    }
}
