import Foundation

/// Sheet and alert state for one note list screen. Owned by `NoteListScreen`
/// and injected so the grid and its cells can raise modals the screen presents.
@Observable
@MainActor
final class NoteListPresentation {
    enum Alert {
        case iCloudDenied
        case archiveAll
        case error(Error)
    }

    var alert: Alert?
    var noteToShare: NoteData?
    var noteToTag: NoteData?

    /// `alert` is the single source of truth; `.alert(isPresented:presenting:)`
    /// needs a Bool binding, and a second stored flag could disagree with it
    var isAlertPresented: Bool {
        get { alert != nil }
        set { if !newValue { alert = nil } }
    }

    func presentOpenFailed() {
        alert = .error(NoteStoreError.openFailed(count: 1))
    }

    // Open-then-present: both sheets take a loaded NoteData, so the document
    // must be opened before the sheet shows
    func requestShare(_ entry: NoteIndexEntry, from store: NoteStore) {
        Task {
            if let note = await store.loadNote(entry) {
                noteToShare = note
            } else {
                presentOpenFailed()
            }
        }
    }

    func requestTag(_ entry: NoteIndexEntry, from store: NoteStore) {
        Task {
            if let note = await store.loadNote(entry) {
                noteToTag = note
            } else {
                presentOpenFailed()
            }
        }
    }
}
