//
//  NotesGrid.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

protocol NotesGridParent {
    func getTagToNote(document: NoteDocument) -> [TagEntity]
    func duplicate(_ document: NoteDocument)
    func archive(_ document: NoteDocument)
    func unarchive(_ document: NoteDocument)
    func delete(_ document: NoteDocument)
    func showActivityView(_ document: NoteDocument)

}

struct NotesGrid: View {
    @State var documentToShare: NoteDocument?
    var documents: [NoteDocument]
    var parent: NotesGridParent
    let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)

    var body: some View {
        LazyVGrid(columns: [gridItem]) {
            ForEach((0..<documents.endIndex), id: \.self) { index in
                VStack {
                    NoteImage(document: documents[index])
                    .contextMenu {
                        Button(
                            action: { duplicate(noteDocument: documents[index]) },
                            label: { Label("Duplicate", systemImage: "doc.on.doc") })
                        if documents[index].isArchived {
                                Button(
                                    action: { unarchive(noteDocument: documents[index]) },
                                    label: { Label("Move to Inbox", systemImage: "tray") })
                                if #available(iOS 15.0, *) {
                                    Button(role: .destructive) {
                                        delete(noteDocument: documents[index])
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        } else {
                            Button(action: { archive(noteDocument: documents[index]) },
                                   label: { Label("Move to Trash", systemImage: "trash") })
                        }
                        Button(action: { share(noteDocument: documents[index]) },
                               label: { Label("Share", systemImage: "square.and.arrow.up") })
                        Button(
                            action: {
                                TagListRouter.shared.showTagList(noteDocument: documents[index])
                            },
                            label: { Label("Tag", systemImage: "tag") })
                    }
                    TagHStack(tags: parent.getTagToNote(document: documents[index]))
                        .padding(.horizontal)
                }
            }
        }
    }

    func duplicate(noteDocument: NoteDocument) {
        parent.duplicate(noteDocument)
    }

    func archive(noteDocument: NoteDocument) {
        parent.archive(noteDocument)
    }

    func unarchive(noteDocument: NoteDocument) {
        parent.unarchive(noteDocument)
    }

    func delete(noteDocument: NoteDocument) {
        parent.delete(noteDocument)
    }

    func share(noteDocument: NoteDocument) {
        parent.showActivityView(noteDocument)
    }
}

// struct NotesGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        NotesGrid()
//    }
// }
