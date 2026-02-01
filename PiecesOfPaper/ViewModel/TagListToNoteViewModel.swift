//
//  TagListToNoteViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

@Observable
final class TagListToNoteViewModel {
    private let tagModel = TagModel()
    private var tags: [TagEntity]
    var noteDocument: NoteDocument
    private(set) var tagsToNote: [TagEntity] = []
    private(set) var tagsNotToNote: [TagEntity] = []

    init(noteDocument: NoteDocument) {
        self.tags = tagModel.fetch()
        self.noteDocument = noteDocument
        updateFilteredTags()
    }

    private func updateFilteredTags() {
        tagsToNote = tags.filter { noteDocument.entity.tags.contains($0) }
        tagsNotToNote = tags.filter { !noteDocument.entity.tags.contains($0) }
    }

    func add(tagName: TagEntity) {
        noteDocument.entity.tags.append(tagName)
        save()
    }

    func remove(tag: TagEntity) {
        noteDocument.entity.tags = noteDocument.entity.tags.filter { $0 != tag }
        save()
    }

    private func save() {
        noteDocument.save(to: noteDocument.fileURL, for: .forOverwriting) { [weak self] success in
            if success {
                self?.updateFilteredTags()
            }
        }
    }
}
