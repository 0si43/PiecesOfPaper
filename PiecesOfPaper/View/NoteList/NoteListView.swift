//
//  NoteListView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteListView: View {
    let directory: NoteDirectory
    @Environment(NoteStore.self) private var noteStore
    @Environment(TagStore.self) private var tagStore
    private let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)

    var body: some View {
        LazyVGrid(columns: [gridItem]) {
            ForEach(noteStore.displayDocuments(for: directory)) { document in
                VStack {
                    NoteView(document: document)
                    .contextMenu {
                        contextMenu(document: document)
                    }
                    NoteListTagHStack(
                        tags: tagStore.tagsFor(document: document),
                        action: {
                            noteStore.documentToTag = document
                        }
                    )
                        .padding(.horizontal)
                }
                .id(document.id)
            }
        }
    }

    func contextMenu(document: NoteDocument) -> some View {
        Group {
            Button {
                noteStore.duplicate(document, in: directory)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            if document.isArchived {
                Button {
                    noteStore.unarchive(document)
                } label: {
                    Label("Move to Inbox", systemImage: "tray")
                }
                Button(role: .destructive) {
                    noteStore.delete(document)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button {
                    noteStore.archive(document)
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
            }
            Button {
                noteStore.documentToShare = document
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                noteStore.documentToTag = document
            } label: {
                Label("Tag", systemImage: "tag")
            }
        }
    }
}
