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
    var documentForPass: NoteDocument?

    private init() { }

    func bind(isShowTagList: Binding<Bool>) {
        self.isShowTagList = isShowTagList
    }

    func showTagList(noteDocument: NoteDocument) {
        documentForPass = noteDocument
        isShowTagList?.wrappedValue.toggle()
    }
}
