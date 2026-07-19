# CLAUDE.md

## Language

- All GitHub-facing text is written in English: PR titles/bodies, issue titles/bodies, commit messages, and code comments.
- Conversation with the user may be in Japanese; the repository's written artifacts stay in English.

## Verification

- Changes that touch the canvas or PencilKit rendering (PKCanvasView, PKDrawing, thumbnails) must be verified on a physical iPad with an Apple Pencil before merge. PencilKit keeps process-wide renderer state that the Simulator and unit tests cannot exercise — rendering `PKDrawing.image` off the main thread breaks stroke drawing app-wide on device only (#187).

## Simulator testing

- Drawing: `PKCanvasViewWrapper` sets `drawingPolicy = .anyInput` under `#if targetEnvironment(simulator)`, so mouse drags draw strokes in the Simulator (on device it stays `.pencilOnly` on iPad). This covers the draw → `canvasViewDrawingDidChange` → autosave → thumbnail flow; renderer-state issues still require a device (see Verification).
- iCloud: run day-to-day Simulator checks with iCloud disabled in the app's settings — `FilePath.savingUrl` falls back to the local Documents directory and all save/load/archive paths work without an iCloud account. For real sync, sign into an Apple ID in the Simulator and use Features > Trigger iCloud Sync (unreliable; smoke checks only).
- Unit tests build non-empty drawings with `PKDrawing.stub()` (`PiecesOfPaperTests/PKDrawingStub.swift`); constructing `PKDrawing` needs no Pencil input.
- `NoteDocument`'s iCloud conflict resolution is not unit-testable: `NSFileVersion.addOfItem(at:withContentsOf:)` — the only API that fabricates file versions — is macOS-only, so iOS tests cannot create conflicting versions. Verify it with two devices syncing over real iCloud.
