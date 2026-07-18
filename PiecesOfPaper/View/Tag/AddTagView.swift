//
//  AddTagView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct AddTagView: View {
    // Snapshot from sheet(item:); read the latest state through the store by id
    let note: NoteData
    @Environment(NoteStore.self) private var noteStore
    @Environment(TagStore.self) private var tagStore

    private var currentNote: NoteData {
        noteStore.note(id: note.id) ?? note
    }

    private var tagsToNote: [TagEntity] {
        tagStore.tagsFor(note: currentNote)
    }

    private var tagsNotToNote: [TagEntity] {
        tagStore.tagsNotFor(note: currentNote)
    }

    var body: some View {
        List {
            TagHStack(tags: tagsToNote, action: remove, deletable: true)
            Section(header: Text("Select tag which you want to add")) {
                ForEach(tagsNotToNote, id: \.id) { tag in
                    HStack {
                        Tag(entity: tag)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        add(tag)
                    }
                }
            }
        }
        .onAppear {
            tagStore.reload()
        }
    }

    private func add(_ tag: TagEntity) {
        noteStore.addTag(tag, to: currentNote)
    }

    private func remove(_ tag: TagEntity) {
        noteStore.removeTag(tag, from: currentNote)
    }
}

#Preview {
    AddTagView(note: NoteData.createTestData())
        .environment(NoteStore())
        .environment(TagStore())
}
