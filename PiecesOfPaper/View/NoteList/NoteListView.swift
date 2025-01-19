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
    private(set) var documents: [NoteDocument]
    private(set) var parent: NoteListViewParent
    private let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)

    var body: some View {
        LazyVGrid(columns: [gridItem]) {
            ForEach((0..<documents.endIndex), id: \.self) { index in
                VStack {
                    NoteView(document: documents[index])
                    .contextMenu {
                        contextMenu(document: documents[index])
                    }
                    TagHStack(tags: parent.getTagToNote(document: documents[index]))
                        .padding(.horizontal)
                }
            }
        }
    }

    func contextMenu(document: NoteDocument) -> some View {
        Group {
            Button {
                parent.duplicate(document)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            if document.isArchived {
                Button {
                    parent.unarchive(document)
                } label: {
                    Label("Move to Inbox", systemImage: "tray")
                }
                Button(role: .destructive) {
                    parent.delete(document)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button {
                    parent.archive(document)
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
            }
            Button {
                parent.showActivityView(document)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                parent.showAddTagView(document)
            } label: {
                Label("Tag", systemImage: "tag")
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
