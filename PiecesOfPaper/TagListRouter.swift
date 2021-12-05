//
//  TagListRouter.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

final class TagListRouter {
    static let shared = TagListRouter()
    private var isShowTagList: Binding<Bool>!
    private var taggingNoteDocument: Binding<NoteDocument?>!
    var documentForPass: NoteDocument?

    private init() { }

    func bind(isShowTagList: Binding<Bool>, taggingNoteDocument: Binding<NoteDocument?>) {
        self.isShowTagList = isShowTagList
        self.taggingNoteDocument = taggingNoteDocument
    }

    func showTagList(noteDocument: NoteDocument) {
//        self.taggingNoteDocument.wrappedValue = noteDocument
        documentForPass = noteDocument
        isShowTagList?.wrappedValue.toggle()
    }
}
