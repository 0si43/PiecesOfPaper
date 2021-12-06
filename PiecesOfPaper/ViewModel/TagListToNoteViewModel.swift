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
    let tagModel = TagModel()
    var tags: [TagEntity]
    var noteDocument: NoteDocument?
    var objectWillChange = ObjectWillChangePublisher()

    var tagsToNote: [TagEntity] {
        guard let noteDocument = noteDocument else { return [] }
        return tags.filter {
            noteDocument.entity.tags.contains($0.name)
        }
    }

    var tagsNotToNote: [TagEntity] {
        guard let noteDocument = noteDocument else { return [] }
        return tags.filter {
            !noteDocument.entity.tags.contains($0.name)
        }
    }

    init() {
        tags = tagModel.fetch()
        noteDocument = TagListRouter.shared.documentForPass
    }

    func add(tagName: String, noteDocument: NoteDocument) {
        noteDocument.entity.tags.append(tagName)
        save(noteDocument: noteDocument)
    }

    private func save(noteDocument: NoteDocument) {
        noteDocument.save(to: noteDocument.fileURL, for: .forOverwriting) { [weak self] success in
            if success {
                self?.objectWillChange.send()
            } else {
                print("save failed")
            }
        }
    }
}
