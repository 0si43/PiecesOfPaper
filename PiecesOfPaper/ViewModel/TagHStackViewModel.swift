//
//  TagHStackViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import Combine

final class TagHStackViewModel: ObservableObject {
    var objectWillChange = ObjectWillChangePublisher()
    var noteDocument: NoteDocument
    var tags: [TagEntity]

    init(noteDocument: NoteDocument, tags: [TagEntity]) {
        self.noteDocument = noteDocument
        self.tags = tags
    }

    private func save() {
        noteDocument.save(to: noteDocument.fileURL, for: .forOverwriting) { [weak self] success in
            if success {
                self?.objectWillChange.send()
            } else {
                print("save failed")
            }
        }
    }
}
