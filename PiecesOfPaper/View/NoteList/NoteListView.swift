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
            ForEach(noteStore.displayEntries(for: directory)) { entry in
                VStack {
                    NoteView(entry: entry)
                    .contextMenu {
                        contextMenu(entry: entry)
                    }
                    NoteListTagHStack(
                        tags: tagStore.tags(ids: noteStore.tagIds(for: entry)),
                        action: {
                            noteStore.requestTag(entry)
                        }
                    )
                        .padding(.horizontal)
                }
            }
        }
    }

    func contextMenu(entry: NoteIndexEntry) -> some View {
        Group {
            Button {
                noteStore.duplicate(entry, in: directory)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            if entry.isArchived {
                Button {
                    noteStore.unarchive(entry)
                } label: {
                    Label("Move to Inbox", systemImage: "tray")
                }
                Button(role: .destructive) {
                    noteStore.delete(entry)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button {
                    noteStore.archive(entry)
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
            }
            Button {
                noteStore.requestShare(entry)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                noteStore.requestTag(entry)
            } label: {
                Label("Tag", systemImage: "tag")
            }
        }
    }
}
