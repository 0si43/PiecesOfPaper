//
//  Notification.Name+.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/16.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

public extension Notification.Name {
    /// added new note
    static let addedNewNote = Notification.Name("addedNewNote")
    /// change tag to note
    static let changedTagToNote = Notification.Name("changedTagToNote")
    /// show add tag view
//    static let showAddTagView = Notification.Name("showAddTagView")
}
