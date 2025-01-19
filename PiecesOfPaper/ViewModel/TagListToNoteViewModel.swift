//
//  TagListToNoteViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import Combine

final class TagListToNoteViewModel: ObservableObject {
    private let tagModel = TagModel()
    private var tags: [TagEntity]
    var noteDocument: NoteDocument?
    var objectWillChange = ObjectWillChangePublisher()

    var tagsToNote: [TagEntity] {
        guard let noteDocument = noteDocument else { return [] }
        return tags.filter {
            noteDocument.entity.tags.contains($0)
        }
    }

    var tagsNotToNote: [TagEntity] {
        guard let noteDocument = noteDocument else { return [] }
        return tags.filter {
            !noteDocument.entity.tags.contains($0)
        }
    }

    init(noteDocument: NoteDocument? = nil) {
        tags = tagModel.fetch()
        if let document = noteDocument {
            self.noteDocument = document
        }
    }

    func add(tagName: TagEntity) {
        guard let noteDocument = noteDocument else { return }
        noteDocument.entity.tags.append(tagName)
        save()
    }

    func remove(tag: TagEntity) {
        guard let noteDocument = noteDocument else { return }
        noteDocument.entity.tags = noteDocument.entity.tags.filter { $0 != tag }
        save()
    }

    private func save() {
        guard let noteDocument = noteDocument else { return }
        noteDocument.save(to: noteDocument.fileURL, for: .forOverwriting) { [weak self] success in
            if success {
                self?.objectWillChange.send()
            } else {
                print("save failed")
            }
        }
    }
}
