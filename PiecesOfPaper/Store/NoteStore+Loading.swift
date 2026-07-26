import Foundation

// MARK: - Display ordering

extension NoteStore {
    var displayInboxEntries: [NoteIndexEntry] {
        reorderEntries(inboxIndex, listOrder: inboxListOrder)
    }

    var displayArchivedEntries: [NoteIndexEntry] {
        reorderEntries(archivedIndex, listOrder: archivedListOrder)
    }

    func displayEntries(for directory: NoteDirectory) -> [NoteIndexEntry] {
        switch directory {
        case .inbox: displayInboxEntries
        case .archived: displayArchivedEntries
        }
    }

    /// Everything a bulk move will touch. `allArchive()` and `allUnarchive()`
    /// iterate the index itself, so counting the displayed entries would
    /// promise the filtered subset and move the rest anyway (issue #322).
    func entryCount(for directory: NoteDirectory) -> Int {
        switch directory {
        case .inbox: inboxIndex.count
        case .archived: archivedIndex.count
        }
    }

    private func reorderEntries(_ entries: [NoteIndexEntry], listOrder: ListOrder) -> [NoteIndexEntry] {
        var filtered = entries
        if !listOrder.filterBy.isEmpty {
            // Tags live inside each document, so only notes with loaded
            // metadata can match while a filter is active — an entry with none
            // has no tag ids and fails the non-empty filter below.
            filtered = filtered.filter { entry in
                let tagIds = tagIds(for: entry)
                return listOrder.filterBy.allSatisfy { tagIds.contains($0.id) }
            }
        }
        let ascending = listOrder.sortOrder == .ascending
        filtered.sort { lhs, rhs in
            let lhsDate = sortDate(of: lhs, by: listOrder.sortBy)
            let rhsDate = sortDate(of: rhs, by: listOrder.sortBy)
            guard lhsDate != rhsDate else {
                return ascending
                    ? lhs.fileURL.lastPathComponent < rhs.fileURL.lastPathComponent
                    : lhs.fileURL.lastPathComponent > rhs.fileURL.lastPathComponent
            }
            return ascending ? lhsDate < rhsDate : lhsDate > rhsDate
        }
        return filtered
    }

    private func sortDate(of entry: NoteIndexEntry, by sortBy: ListOrder.SortBy) -> Date {
        switch sortBy {
        case .updatedDate: entry.updatedDate
        case .createdDate: entry.createdDate
        }
    }
}

// MARK: - Load-on-demand accessors

extension NoteStore {
    /// Tag ids for a list row; empty until the row's document has been opened.
    ///
    /// Read straight from the cache rather than through `validMetadata`: that
    /// check compares the cache's date with the index entry's, and on iCloud the
    /// two come from different sources — the entry's from the metadata query, the
    /// cache's from the local file the write-back stamped. Any enumeration
    /// between a tag edit and the next render broke the match and emptied a row
    /// whose tags were on disk. The date only says whether the rendered drawing
    /// is stale, which is what the thumbnail still asks about.
    func tagIds(for entry: NoteIndexEntry) -> [UUID] {
        metadataByFileName[entry.fileName]?.tagIds ?? []
    }

    func salvageLegacyTags(of note: NoteData) {
        guard !note.entity.legacyTags.isEmpty else { return }
        onLegacyTagsDecoded?(note.entity.legacyTags)
    }
}

// MARK: - Tag-filter hydration

extension NoteStore {
    func isFilterHydrating(for directory: NoteDirectory) -> Bool {
        hydratingDirectories.contains(directory)
    }

    /// Tags live inside each document, so an active tag filter can only match
    /// notes whose metadata is loaded. Opens every entry lacking valid
    /// metadata in the background — discarding the drawings — so the filtered
    /// list fills in progressively.
    func ensureMetadataForFilter(directory: NoteDirectory) {
        hydrationTasks[directory]?.cancel()
        hydrationTasks[directory] = nil
        hydratingDirectories.remove(directory)
        guard !listOrder(for: directory).filterBy.isEmpty else { return }

        hydratingDirectories.insert(directory)
        hydrationTasks[directory] = Task {
            // The persisted cache usually covers the whole directory, so the
            // pending set must be computed after it has been read
            await loadPersistedMetadataTask?.value
            let index = directory == .inbox ? inboxIndex : archivedIndex
            let pending = index.filter { validMetadata(for: $0) == nil }
            await withTaskGroup(of: Void.self) { group in
                var iterator = pending.makeIterator()
                // Width-limited so only a few drawings are decoded at a time
                for _ in 0..<4 {
                    guard let entry = iterator.next() else { break }
                    group.addTask { _ = await self.loadNote(entry) }
                }
                for await _ in group {
                    guard !Task.isCancelled, let entry = iterator.next() else { continue }
                    group.addTask { _ = await self.loadNote(entry) }
                }
            }
            // A cancelled run leaves the state to the ensure call that
            // cancelled it
            if !Task.isCancelled {
                hydratingDirectories.remove(directory)
                hydrationTasks[directory] = nil
            }
        }
    }
}
