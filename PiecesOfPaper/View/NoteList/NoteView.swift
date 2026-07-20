//
//  NoteView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct NoteView: View {
    let entry: NoteIndexEntry
    @Environment(NoteStore.self) private var noteStore
    @State private var thumbnail: UIImage?
    @State private var loadedNote: NoteData?
    @State private var isOpening = false

    var body: some View {
        Button(action: openCanvas, label: {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.clear
                }
            }
            .frame(width: 250, height: 190)
            .background(Color(UIColor.secondarySystemBackground))
            .shadow(radius: 5)
            .overlay {
                if isOpening {
                    ProgressView()
                }
            }
        })
        .accessibilityLabel("Note")
        .task(id: entry.updatedDate) {
            let key = ThumbnailCache.key(for: entry)
            if let cached = ThumbnailCache.shared.cached(key: key),
               noteStore.validMetadata(for: entry) != nil {
                thumbnail = cached
                return
            }
            // Open the one document, render, and let the drawing go out of
            // scope; a failed open leaves the placeholder and the next
            // appearance retries.
            guard let note = await noteStore.loadNote(entry) else { return }
            guard !Task.isCancelled else { return }
            thumbnail = await ThumbnailCache.shared.thumbnail(for: note.entity.drawing, key: key)
        }
        .fullScreenCover(item: $loadedNote) { note in
            NavigationView {
                CanvasView(note: note)
            }
        }
    }

    // Open-then-present: CanvasView reads the drawing synchronously in
    // onAppear, so the document must be loaded before the cover shows
    private func openCanvas() {
        guard !isOpening else { return }
        isOpening = true
        Task {
            let note = await noteStore.loadNote(entry)
            isOpening = false
            if let note {
                loadedNote = note
            } else {
                noteStore.presentOpenFailedAlert()
            }
        }
    }
}

#Preview {
    NoteView(entry: NoteIndexEntry(fileURL: URL(fileURLWithPath: "/preview/2026-01-01-00-00-000000.pop"),
                                   creationDate: nil,
                                   contentModificationDate: nil))
        .environment(NoteStore())
}
