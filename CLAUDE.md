# CLAUDE.md

- Known pitfalls (PencilKit, Xcode, pbxproj): see [docs/GOTCHAS.md](docs/GOTCHAS.md)
- Progress log: see [docs/PROGRESS.md](docs/PROGRESS.md). When resuming work, read its Current Status and any unconsolidated fragments in [docs/progress/](docs/progress/)

## Language

- All GitHub-facing text is written in English: PR titles/bodies, issue titles/bodies, commit messages, and code comments.
- Conversation with the user may be in Japanese; the repository's written artifacts stay in English.

## Build & test

```
xcodebuild -project <absolute path>/PiecesOfPaper.xcodeproj -scheme PiecesOfPaper \
  -destination 'platform=iOS Simulator,name=<simulator name>' build   # or: test
```

- Pass `-project` as an absolute path; the `platform=iOS Simulator,` prefix is required (see docs/GOTCHAS.md for both).

## Verification

- Changes that touch the canvas or PencilKit rendering (PKCanvasView, PKDrawing, thumbnails) must be verified on a physical iPad with an Apple Pencil before merge. PencilKit keeps process-wide renderer state that the Simulator and unit tests cannot exercise — rendering `PKDrawing.image` off the main thread breaks stroke drawing app-wide on device only (#187). More PencilKit pitfalls: docs/GOTCHAS.md.

## Simulator testing

- Drawing: `PKCanvasViewWrapper` sets `drawingPolicy = .anyInput` under `#if targetEnvironment(simulator)`, so mouse drags draw strokes in the Simulator (on device it stays `.pencilOnly` on iPad). This covers the draw → `canvasViewDrawingDidChange` → autosave → thumbnail flow; renderer-state issues still require a device (see Verification).
- iCloud: run day-to-day Simulator checks with iCloud disabled in the app's settings — `FilePath.savingUrl` falls back to the local Documents directory and all save/load/archive paths work without an iCloud account. For real sync, sign into an Apple ID in the Simulator and use Features > Trigger iCloud Sync (unreliable; smoke checks only).
- Unit tests build non-empty drawings with `PKDrawing.stub()` (`PiecesOfPaperTests/PKDrawingStub.swift`); constructing `PKDrawing` needs no Pencil input.

## Progress workflow

- Every PR includes one new fragment file `docs/progress/YYYY-MM-DD-<slug>.md` instead of editing `docs/PROGRESS.md` directly (format: [docs/progress/README.md](docs/progress/README.md)).
- In `docs/PROGRESS.md`, only the Current Status section is edited by hand. The Work Log is written exclusively by `swift scripts/consolidate-progress.swift`, run on the user's request, one run at a time, with the result in a chore PR.
