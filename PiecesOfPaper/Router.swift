//
//  Router.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/19.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation
import SwiftUI
import PencilKit

final class Router {
    static let shared = Router()
    private var isShowCanvas: Binding<Bool>!
    private var noteDocument: Binding<NoteDocument?>!

    private init() { }

    /// This procedure should been done by initializer, but a singleton instance couldn't have arguments
    func bind(isShowCanvas: Binding<Bool>, noteDocument: Binding<NoteDocument?>) {
        self.isShowCanvas = isShowCanvas
        self.noteDocument = noteDocument
    }

    /// open a full screen canvas and make new drawing data
    func openNewCanvas() {
        self.noteDocument.wrappedValue = nil
        toggleStateValue()
    }

    /// open a full screen canvas with drawing data
    func openCanvas(noteDocument: NoteDocument) {
        self.noteDocument.wrappedValue = noteDocument
        toggleStateValue()
    }

    private func toggleStateValue() {
        isShowCanvas?.wrappedValue.toggle()
    }
}
