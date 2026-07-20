import SwiftUI
import PencilKit

struct NoteThumbnailView: View {
    let entry: NoteIndexEntry
    @Environment(NoteStore.self) private var noteStore
    @State private var thumbnail: UIImage?
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
                noteStore.openedNote = note
            } else {
                noteStore.presentOpenFailedAlert()
            }
        }
    }
}

#Preview {
    NoteThumbnailView(entry: NoteIndexEntry(fileURL: URL(fileURLWithPath: "/preview/2026-01-01-00-00-000000.pop"),
                                            creationDate: nil,
                                            contentModificationDate: nil))
        .environment(NoteStore())
}
