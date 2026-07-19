# Development Progress Log

Where to resume in the next session. Read **Current Status** first, then check
[docs/progress/](progress/) for fragments not yet consolidated into the Work Log.

Only Current Status is edited by hand. The Work Log is appended to exclusively by
`swift scripts/consolidate-progress.swift` (see [progress/README.md](progress/README.md)).

## Current Status

- Phase: post-migration cleanup and feature work. The View + Store + Repository migration is complete (ViewModels removed in PR #186).
- The device-only canvas breakage from off-main thumbnail rendering is fixed (issue #187, PR #189), and the on-device verification rule for PencilKit changes is documented in CLAUDE.md (PR #191).
- Latest merge: iCloud notes are enumerated via NSMetadataQuery so undownloaded notes stay listed (PR #192).
- Next: the only open issue is #184 — show note files as drawing thumbnails in the Files app (custom UTType + QuickLook Thumbnail Extension).

## Work Log

### 2026-07-19

- [x] Enumerate iCloud notes via NSMetadataQuery so undownloaded notes stay listed (PR #192)
- [x] Document on-device verification requirement for PencilKit changes (PR #191)
- [x] Render note thumbnails on the main actor to fix broken Pencil drawing on device (issue #187, PR #189)
  - Root cause: off-main `PKDrawing.image` breaks PKCanvasView rendering process-wide, device-only — see docs/GOTCHAS.md
- [x] Remove remaining ViewModels to complete the View + Store + Repository migration (PR #186)

### 2026-07-18

- [x] Remove racy post-close refetch that could hide a just-saved note (issue #164, PR #182)
- [x] Add CLAUDE.md documenting the English-language convention (issue #180, PR #181)
- [x] Separate NoteDocument responsibilities: file I/O vs view state (PR #179)
- [x] Add unit tests for Store-layer persistence (issue #177, PR #178)

### 2026-07-12

- [x] Restore SwiftLint and CI, clean up stale project naming (PR #176)
- [x] Cache note thumbnails and the iCloud container URL (PR #174)
- [x] Add privacy manifest, VoiceOver labels, and drop deprecated UIScreen.main (PR #172)

### 2026-07-11

- [x] Fix silent data-loss paths in note persistence (PR #170)
- [x] Complete the Store/Repository architecture migration (PR #168)
