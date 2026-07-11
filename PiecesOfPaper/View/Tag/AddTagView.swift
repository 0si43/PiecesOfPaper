//
//  AddTagView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct AddTagView: View {
    private(set) var document: NoteDocument
    @Environment(NoteStore.self) private var noteStore
    @Environment(TagStore.self) private var tagStore
    @State private var tagsToNote: [TagEntity] = []
    @State private var tagsNotToNote: [TagEntity] = []

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
            updateFilteredTags()
        }
    }

    private func updateFilteredTags() {
        tagsToNote = tagStore.tagsFor(document: document)
        tagsNotToNote = tagStore.tagsNotFor(document: document)
    }

    private func add(_ tag: TagEntity) {
        noteStore.addTag(tag, to: document)
        updateFilteredTags()
    }

    private func remove(_ tag: TagEntity) {
        noteStore.removeTag(tag, from: document)
        updateFilteredTags()
    }
}

#Preview {
    AddTagView(document: NoteDocument.createTestData())
        .environment(NoteStore())
        .environment(TagStore())
}
