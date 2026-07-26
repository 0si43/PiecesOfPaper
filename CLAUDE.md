# CLAUDE.md

- Known pitfalls (PencilKit, Xcode, pbxproj): see [docs/GOTCHAS.md](docs/GOTCHAS.md)
- Progress log: see [docs/PROGRESS.md](docs/PROGRESS.md). When resuming work, read its Current Status and any unconsolidated fragments in [docs/progress/](docs/progress/)

## Scope

- This is a free app maintained by one person. A defect in what the app *says* is worth fixing on
  the spot; a defect that needs new code to cover a rare state is a judgement call for the
  maintainer. Bring it with its cost and the alternatives rather than building it by reflex — the
  finger-drawing notice appearing on a fresh install was reviewed, costed and deliberately left
  alone (PR #305).

## Language

- All GitHub-facing text is written in English: PR titles/bodies, issue titles/bodies, commit messages, and code comments.
- Conversation with the user may be in Japanese; the repository's written artifacts stay in English.

## Build & test

```
xcodebuild -project <absolute path>/PiecesOfPaper.xcodeproj -scheme PiecesOfPaper \
  -destination 'platform=iOS Simulator,name=<simulator name>' build   # or: test
```

- Pass `-project` as an absolute path; the `platform=iOS Simulator,` prefix is required (see docs/GOTCHAS.md for both).

## Lint

- Run `swiftlint` before each commit, not after batching several. Opt-in rules
  (e.g. `force_unwrapping`) apply to `PiecesOfPaperTests` too, and fixing a
  warning after later commits exist forces a history rewrite.
- `xcodebuild` includes a SwiftLint autocorrect build phase ("Correcting ..."),
  so a build or test run can rewrite source files. Check `git status` after
  builds before assuming the working tree still matches the last commit.

## Verification

- Changes that touch the canvas or PencilKit rendering (PKCanvasView, PKDrawing, thumbnails) must be verified on a physical iPad with an Apple Pencil before merge. PencilKit keeps process-wide renderer state that the Simulator and unit tests cannot exercise — rendering `PKDrawing.image` off the main thread breaks stroke drawing app-wide on device only (#187). More PencilKit pitfalls: docs/GOTCHAS.md.

## Simulator testing

- Drawing: on device the canvas leaves `drawingPolicy` at `.default`, so a finger draws only while the tool picker is visible and the system "Only Draw with Apple Pencil" setting is off (issue #271). `PKCanvasViewWrapper` overrides it to `.anyInput` under `#if targetEnvironment(simulator)`, so mouse drags draw strokes in the Simulator whatever that setting says. This covers the draw → `canvasViewDrawingDidChange` → autosave → thumbnail flow; renderer-state issues still require a device (see Verification).
- The canvas launches with its chrome visible: a floating control panel (Note Information / Share / Done) in the top-right corner and the tool picker. Both bars stay hidden at all times, so the panel is the only chrome on screen and `idb ui tap` can reach Done directly.
- Hiding the chrome (paper-only mode) in the Simulator is a **two-finger tap = Option+click** (Simulator-only gesture); a second one brings it back. Single taps start strokes under `.anyInput` and never reach the `TapGesture` that toggles the UI. On device the same holds whenever a finger draws, so paper-only mode is only offered while "Only Draw with Apple Pencil" is on — `CanvasView.tapGesture` refuses to enter it otherwise. The Simulator's two-finger tap goes through `onToggleUI`, which bypasses that guard, so the mode stays inspectable there.
- iCloud: run day-to-day Simulator checks with iCloud disabled in the app's settings — `FilePath.savingUrl` falls back to the local Documents directory and all save/load/archive paths work without an iCloud account. For real sync, sign into an Apple ID in the Simulator and use Features > Trigger iCloud Sync (unreliable; smoke checks only).
- Unit tests build non-empty drawings with `PKDrawing.stub()` (`PiecesOfPaperTests/PKDrawingStub.swift`); constructing `PKDrawing` needs no Pencil input.
- Command-line E2E (drawing injection, accessibility assertions) via idb: see [docs/SIMULATOR_E2E.md](docs/SIMULATOR_E2E.md).

## Repository-wide mechanical changes

- A commit that rewrites many files mechanically (header removal, reformatting) must have its SHA appended to `.git-blame-ignore-revs`, in a follow-up commit within the same PR. GitHub honors the file automatically; locally it needs `git config blame.ignoreRevsFile .git-blame-ignore-revs`.

## Progress workflow

- Every PR includes one new fragment file `docs/progress/YYYY-MM-DD-<slug>.md` instead of editing `docs/PROGRESS.md` directly (format: [docs/progress/README.md](docs/progress/README.md)).
- In `docs/PROGRESS.md`, only the Current Status section is edited by hand. The Work Log is written exclusively by `swift scripts/consolidate-progress.swift`, run on the user's request, one run at a time, with the result in a chore PR.
