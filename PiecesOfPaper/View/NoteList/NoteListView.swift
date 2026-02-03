//
//  NoteListView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteListView: View {
    @Bindable var viewModel: NoteViewModel
    private let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)

    var body: some View {
        LazyVGrid(columns: [gridItem]) {
            ForEach(viewModel.displayNoteDocuments) { document in
                VStack {
                    NoteView(document: document)
                    .contextMenu {
                        contextMenu(document: document)
                    }
                    NoteListTagHStack(
                        tags: viewModel.getTagToNote(document: document),
                        action: {
                            viewModel.documentToTag = document
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
                viewModel.duplicate(document)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            if document.isArchived {
                Button {
                    viewModel.unarchive(document)
                } label: {
                    Label("Move to Inbox", systemImage: "tray")
                }
                Button(role: .destructive) {
                    viewModel.delete(document)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button {
                    viewModel.archive(document)
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
            }
            Button {
                viewModel.documentToShare = document
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                viewModel.documentToTag = document
            } label: {
                Label("Tag", systemImage: "tag")
            }
        }
    }
}
