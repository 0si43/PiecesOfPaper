import Foundation
import os

// MARK: - Data operations

extension NoteStore {
    func duplicate(_ entry: NoteIndexEntry, in directory: NoteDirectory) async throws {
        let note: NoteData
        switch await loadNoteResult(entry) {
        case .success(let loaded):
            note = loaded
        case .failure(let error):
            throw NoteStoreError.openFailure(from: error, count: 1)
        }
        let newNote: NoteData? = await withCheckedContinuation { continuation in
            noteRepository.duplicate(note, in: directory) { continuation.resume(returning: $0) }
        }
        guard let newNote else { throw NoteStoreError.saveFailed }
        applySaved(newNote)
    }

    // Coordinated delete is async, so the index is updated optimistically and
    // rolled back on failure; the caller (the view) surfaces the thrown error.
    // A repeated tap is a no-op: the entry is already gone from the index.
    func delete(_ entry: NoteIndexEntry) async throws {
        guard let sourceDirectory = directory(of: entry.fileURL) else { return }
        let metadata = metadataByFileName[entry.fileName]
        pendingFileOperationUrls.insert(entry.fileURL)
        removeEntryFromIndexes(entry.fileURL)
        metadataByFileName[entry.fileName] = nil
        do {
            try await noteRepository.delete(fileUrl: entry.fileURL)
        } catch {
            restoreEntry(entry, to: sourceDirectory, metadata: metadata)
            pendingFileOperationUrls.remove(entry.fileURL)
            throw NoteStoreError.deleteFailed
        }
        pendingFileOperationUrls.remove(entry.fileURL)
        schedulePersist()
    }

    func archive(_ entry: NoteIndexEntry) async throws {
        try await move(entry, to: .archived)
    }

    func unarchive(_ entry: NoteIndexEntry) async throws {
        try await move(entry, to: .inbox)
    }

    /// Continues past individual failures — a note whose move fails stays in
    /// place (each move rolls itself back), and the total is reported at the end.
    func allArchive() async throws {
        try await moveAll(inboxIndex, to: .archived)
    }

    func allUnarchive() async throws {
        try await moveAll(archivedIndex, to: .inbox)
    }

    private func moveAll(_ entries: [NoteIndexEntry], to directory: NoteDirectory) async throws {
        var failedCount = 0
        for entry in entries {
            do {
                try await move(entry, to: directory)
            } catch {
                failedCount += 1
            }
        }
        if failedCount > 0 {
            throw NoteStoreError.bulkMoveFailed(count: failedCount)
        }
    }

    private func move(_ entry: NoteIndexEntry, to directory: NoteDirectory) async throws {
        guard let sourceDirectory = self.directory(of: entry.fileURL) else { return }
        let metadata = metadataByFileName[entry.fileName]
        pendingFileOperationUrls.insert(entry.fileURL)
        removeEntryFromIndexes(entry.fileURL)
        do {
            let newUrl = try await noteRepository.move(fileUrl: entry.fileURL, to: directory)
            upsertEntry(entry.moved(to: newUrl), in: directory)
            // The metadata cache is keyed by file name, which a move preserves,
            // so the moved note keeps its tags without a re-open
        } catch {
            restoreEntry(entry, to: sourceDirectory, metadata: metadata)
            pendingFileOperationUrls.remove(entry.fileURL)
            throw NoteStoreError.moveFailed
        }
        pendingFileOperationUrls.remove(entry.fileURL)
    }

    // MARK: - Tag operations

    func addTag(_ tag: TagEntity, to note: NoteData) async throws {
        try await updateTagIds(of: note) { $0 + [tag.id] }
    }

    func removeTag(_ tag: TagEntity, from note: NoteData) async throws {
        try await updateTagIds(of: note) { tagIds in tagIds.filter { $0 != tag.id } }
    }

    /// The caller's snapshot may predate tag edits made elsewhere; the
    /// metadata cache holds the latest known tags for the file.
    func currentTagIds(for note: NoteData) -> [UUID] {
        metadataByFileName[note.fileName]?.tagIds ?? note.entity.tagIds
    }

    private func updateTagIds(of note: NoteData, _ transform: ([UUID]) -> [UUID]) async throws {
        let previous = metadataByFileName[note.fileName]
        var updated = note
        updated.entity.tagIds = transform(currentTagIds(for: note))
        // Optimistic cache update so the tag sheet and list rows reflect
        // the change before the save lands; rolled back on failure.
        metadataByFileName[note.fileName] = NoteMetadata(
            id: previous?.id ?? note.entity.id,
            tagIds: updated.entity.tagIds,
            updatedDate: previous?.updatedDate ?? entry(for: note.fileURL)?.updatedDate ?? note.entity.updatedDate
        )
        schedulePersist()
        do {
            try await noteRepository.save(updated.entity, to: updated.fileURL)
        } catch {
            metadataByFileName[note.fileName] = previous
            schedulePersist()
            throw NoteStoreError.saveFailed
        }
        applySaved(updated)
    }

    // MARK: - Index write-back

    /// Refreshes the index entry and metadata for a note just written to disk.
    /// Dates are read back from the file so the entry matches what the next
    /// enumeration reports; a mismatch would invalidate the thumbnail and
    /// force one extra document open per saved note.
    func applySaved(_ note: NoteData) {
        let attributes = noteRepository.fileAttributes(at: note.fileURL)
        let entry = NoteIndexEntry(fileURL: note.fileURL,
                                   creationDate: attributes?.creationDate ?? note.entity.createdDate,
                                   contentModificationDate: attributes?.contentModificationDate ?? note.entity.updatedDate)
        metadataByFileName[note.fileName] = NoteMetadata(id: note.entity.id,
                                                         tagIds: note.entity.tagIds,
                                                         updatedDate: entry.updatedDate)
        schedulePersist()
        if note.isArchived {
            upsertEntry(entry, in: .archived)
        } else if note.isInInbox {
            upsertEntry(entry, in: .inbox)
        } else if let fallback = note.fallbackDirectory {
            // The note sits in a managed folder of some other container: the
            // storage location changed between minting the URL and saving
            // (issue #225). Dropping it here would hide a file that saved
            // fine, so list it; the entry lasts until the next wholesale fetch.
            Logger.noteStore.warning("""
            Saved note \(note.fileURL.path, privacy: .public) is outside the current container \
            (inbox: \(FilePath.inboxUrl?.path ?? "nil", privacy: .public))
            """)
            upsertEntry(entry, in: fallback)
        }
        // Notes outside any managed folder (opened in place from the Files
        // app) are edited at their own URL and never listed
    }

    // MARK: - Private helpers

    private func entry(for fileUrl: URL) -> NoteIndexEntry? {
        inboxIndex.first { $0.fileURL == fileUrl } ?? archivedIndex.first { $0.fileURL == fileUrl }
    }

    private func directory(of fileUrl: URL) -> NoteDirectory? {
        if inboxIndex.contains(where: { $0.fileURL == fileUrl }) { return .inbox }
        if archivedIndex.contains(where: { $0.fileURL == fileUrl }) { return .archived }
        return nil
    }

    private func restoreEntry(_ entry: NoteIndexEntry, to directory: NoteDirectory, metadata: NoteMetadata?) {
        upsertEntry(entry, in: directory)
        metadataByFileName[entry.fileName] = metadata
    }
}
