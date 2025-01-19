//
//  NoteListView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

protocol NoteListViewParent {
    func getTagToNote(document: NoteDocument) -> [TagEntity]
    func duplicate(_ document: NoteDocument)
    func archive(_ document: NoteDocument)
    func unarchive(_ document: NoteDocument)
    func delete(_ document: NoteDocument)
    func showActivityView(_ document: NoteDocument)
    func showAddTagView(_ document: NoteDocument)
}

struct NoteListView: View {
    var documents: [NoteDocument]
    var parent: NoteListViewParent
    let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)

    var body: some View {
        LazyVGrid(columns: [gridItem]) {
            ForEach((0..<documents.endIndex), id: \.self) { index in
                VStack {
                    NoteView(document: documents[index])
                    .contextMenu {
                        Button(
                            action: { parent.duplicate(documents[index]) },
                            label: { Label("Duplicate", systemImage: "doc.on.doc") })
                        if documents[index].isArchived {
                                Button(
                                    action: { parent.unarchive(documents[index]) },
                                    label: { Label("Move to Inbox", systemImage: "tray") })
                                Button(role: .destructive) {
                                    parent.delete(documents[index])
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                        } else {
                            Button(action: { parent.archive(documents[index]) },
                                   label: { Label("Move to Trash", systemImage: "trash") })
                        }
                        Button(action: { parent.showActivityView(documents[index]) },
                               label: { Label("Share", systemImage: "square.and.arrow.up") })
                        Button(
                            action: {
                                parent.showActivityView(documents[index])
                            },
                            label: { Label("Tag", systemImage: "tag") })
                    }
                    TagHStack(tags: parent.getTagToNote(document: documents[index]))
                        .padding(.horizontal)
                }
            }
        }
    }
}

 struct NoteListView_Previews: PreviewProvider {
     static var parent = NoteListParentView(viewModel: NotesViewModel(targetDirectory: .inbox))
     static var array = Array(repeating: NoteDocument.createTestData(), count: 9)
     static var previews: some View {
         NoteListView(documents: array, parent: parent)
    }
 }
