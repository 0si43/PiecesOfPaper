# GOTCHAS

Pitfalls encountered during development, split out of [CLAUDE.md](../CLAUDE.md).
Each entry links to the issue/PR where the details live.

## PencilKit / Canvas

- **Never call `PKDrawing.image(from:scale:)` off the main actor**: calling it even once from a background context (e.g. `Task.detached`) breaks `PKCanvasView` stroke rendering process-wide — the Pencil stops drawing and existing notes render blank. Device-only; the Simulator and unit tests cannot reproduce it. Render thumbnails via `MainActor.run`. Details: issue #187, PR #189.
- **Don't trust a single on-device OK/NG observation while bisecting**: during the #187 bisect, wrapping `CanvasView` in `GeometryReader` looked like an independent cause, but an isolation build (main + thumbnail fix only) drew fine — the observation was flaky. Before shipping a fix, back each suspected cause with an isolation build that adds/removes only that element.
- **`PKDrawing(strokes:)` crashes in the macOS `swift` interpreter**: PKReplicaManager touches CFPreferences and crashes when a drawing with strokes is created from a script. When seeding note files from macOS, use an empty `PKDrawing()` — thumbnails come out blank, but that is enough to exercise the list pipeline.

## iCloud / UIDocument

- **`NoteDocument`'s conflict resolution is not unit-testable on iOS**: `NSFileVersion.addOfItem(at:withContentsOf:)` — the only API that fabricates file versions — is macOS-only, so iOS tests cannot create conflicting versions locally. Verify conflict handling with two devices syncing over real iCloud. Background: issue #196, PR #197.
- **Never `close()` a `UIDocument` whose `open()` failed**: the close completion handler is never invoked for a document that never opened, so the caller awaits forever. `NoteRepository.open` closes only after a successful open. Symptom that found it: the test runner printed "Restarting after unexpected exit, crash, or test timeout" with **no crash report (.ips) and a minutes-long gap** — a hang, not a crash. Trace how far the document got with `xcrun simctl spawn <udid> log show --predicate 'eventMessage CONTAINS "<file>"'` (UIDocumentLog logs every phase). Background: issue #198, PR #208.
- **`UIDocument.open()` on a missing file waits forever by design**: the coordinated read treats it as an undownloaded iCloud item and waits for the download. Don't write a "missing file throws" test — use a corrupt file to exercise the failure path. Background: PR #208.

## SwiftUI

- **Alerts attached below a `fullScreenCover` never show while the cover is up**: `NoteListParentView` has `.alert(isPresented: $noteStore.showAlert)`, but while `CanvasView` is presented via `.fullScreenCover`, that alert is not displayed. Do not refactor cover-side errors onto the store's `showAlert`/`alertType` pattern — errors shown on top of a cover must live in a view-local `@State` + `.alert` inside the cover. The store alert pattern is for the list screens only. Background: PR #186 review.
- **`fullScreenCover`/`sheet` content only inherits environment values injected *outside* the modifier's attachment point**: attaching a cover after `.environment(store)` in the chain (i.e. outside it) crashes at presentation with "No Observable object of type NoteStore found". Attach presentation modifiers *inside* the `.environment` chain — `RootSplitView` does this deliberately. Background: PR #208.

## Xcode / build

- **`-destination` needs the `platform=iOS Simulator,` prefix**: without it, destination resolution is flaky ("Unable to find a destination" appears intermittently).
- **GitHub Actions runners intermittently report no simulators at all**: the test job fails at destination resolution with an "Available destinations" list containing only the two placeholder rows (`Any iOS Device` / `Any iOS Simulator Device`) — CoreSimulator is not returning its device list. Unrelated to the code under test (has hit docs-only commits); rerunning the same commit passes. `test.yml` waits for `xcrun simctl list devices available` to list the target device and retries `xcodebuild test` only when the failure log matches this signature. If it still fails, rerun the job. Details: issue #211.
- **Xcode 26.6 (iOS 26.5 SDK) fails asset catalog compilation without the matching simulator runtime**: actool's `CompileAssetCatalogVariant thinned` step always fails when the iOS 26.5 simulator runtime is not installed, even though Swift compilation succeeds. Fix: `xcodebuild -downloadPlatform iOS` (~8.5 GB).
- **Checking out commits older than mid-2026 loses the shared scheme**: `PiecesOfPaper.xcodeproj/xcshareddata/xcschemes/PiecesOfPaper.xcscheme` was untracked (excluded by `.gitignore`) until July 2026. Checking out an older commit (e.g. tag 3.3.0) leaves Xcode with "No Scheme". Recover with `git show <newer-commit>:PiecesOfPaper.xcodeproj/xcshareddata/xcschemes/PiecesOfPaper.xcscheme` — the target IDs are unchanged. When switching back, delete the now-untracked scheme first or it blocks the checkout.
- **`Executed 0 tests, with 0 failures` in a `xcodebuild test` log is not a failure**: the tests are written with swift-testing (`import Testing`), so the XCTest-derived summary line always reports 0 and `grep 'Test case .* passed'` matches nothing. The real result is the `✔ Test run with N tests in M suites passed` line — check that for the count.
- **The bundle ID is `Individual.LikeAPaper`**, kept from the app's previous name. Anything keyed by bundle ID (simulator `defaults`, app containers) uses this, not `PiecesOfPaper`.
- **Tests import the app as `Pieces_of_Paper`**: the product name is "Pieces of Paper", so the module name substitutes underscores for the spaces. `@testable import PiecesOfPaper` — the name of the target, the project, and the source directory — fails with "unable to resolve module dependency". Copy the import block from an existing test file when adding one.

## project.pbxproj

- **Source files are not listed in the project file at all**: the four top-level folders are file system synchronized folders (`PBXFileSystemSynchronizedRootGroup`, `objectVersion = 77`), so membership follows the directory tree. Add, rename, move or delete a `.swift` file on disk and the build picks it up with no pbxproj edit — never hand-add `PBXBuildFile`/`PBXFileReference` entries for one. The project requires Xcode 16 or later to open. Background: issue #241, PR #242.
- **A membership exception flips the default in whichever direction applies**: `membershipExceptions` in a `PBXFileSystemSynchronizedBuildFileExceptionSet` lists paths whose membership differs from the folder's default *for that target*. For the folder's own target it excludes (`Info.plist` in each folder, `PiecesOfPaper.entitlements`); for any other target it includes — that is how `Model/NoteEntity.swift` and `Model/TagEntity.swift` reach the two QuickLook extension targets. Confirm the outcome in the `*.SwiftFileList` files under DerivedData rather than by reading the pbxproj.
- **`Info.plist` must stay excluded from its own folder's target**: without the exception the synchronized folder copies it as a resource and the build fails with "Multiple commands produce .../Info.plist".
- **Never match pbxproj lines by substring when editing with a script**: a filter on lines containing `SettingViewModel.swift` also matched `ListOrderSettingViewModel.swift` and deleted it. Match exactly, by object ID or by the `/* Foo.swift */` comment form.
- **Verify pbxproj edits with a clean build**: an incremental build can hide a file dropped from Sources behind a stale swiftmodule.
- **Pass `-project` as an absolute path in worktree sessions**: both the main checkout and worktrees contain `PiecesOfPaper.xcodeproj`, and the shell cwd can silently revert to the launch directory, making xcodebuild build the wrong tree — especially dangerous for background runs.

## QuickLook extensions

- **A data-based preview provider must conform to `QLPreviewingController`**: subclassing `QLPreviewProvider` and implementing `providePreview(for:)` is not enough — without the conformance the method is never exposed to the Quick Look host, and the extension loads but silently shows the generic icon. The Xcode template includes the conformance; keep it. Background: PR #193.
- **Cap preview renders by total pixels, not longest side**: on device, ~3.4M-pixel renders were jetsammed in the preview extension while ~1M-pixel renders survived. A longest-side cap lets screen-sized unexpanded drawings through at full display scale, making exactly those notes the largest bitmaps — they failed while bigger expanded canvases (scaled down by the cap) succeeded. `PreviewProvider` caps total pixels at 2M. Diagnosis pattern: thumbnails OK + preview shows the generic icon + failures cluster by drawing size ⇒ render cost, not decode. Background: PR #193.
- **Off-main `PKDrawing.image` is safe inside the QuickLook extensions**: the #187 process-wide breakage requires a `PKCanvasView` in the same process; the extensions have none. Do not "fix" their off-main rendering. Background: PR #193.
