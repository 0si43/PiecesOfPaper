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
            ForEach(noteStore.displayNotes(for: directory)) { note in
                VStack {
                    NoteView(note: note)
                    .contextMenu {
                        contextMenu(note: note)
                    }
                    NoteListTagHStack(
                        tags: tagStore.tagsFor(note: note),
                        action: {
                            noteStore.noteToTag = note
                        }
                    )
                        .padding(.horizontal)
                }
                .id(note.id)
            }
        }
    }

    func contextMenu(note: NoteData) -> some View {
        Group {
            Button {
                noteStore.duplicate(note, in: directory)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            if note.isArchived {
                Button {
                    noteStore.unarchive(note)
                } label: {
                    Label("Move to Inbox", systemImage: "tray")
                }
                Button(role: .destructive) {
                    noteStore.delete(note)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button {
                    noteStore.archive(note)
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
            }
            Button {
                noteStore.noteToShare = note
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                noteStore.noteToTag = note
            } label: {
                Label("Tag", systemImage: "tag")
            }
        }
    }
}
