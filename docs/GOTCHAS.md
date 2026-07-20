# GOTCHAS

Pitfalls encountered during development, split out of [CLAUDE.md](../CLAUDE.md).
Each entry links to the issue/PR where the details live.

## PencilKit / Canvas

- **Never call `PKDrawing.image(from:scale:)` off the main actor**: calling it even once from a background context (e.g. `Task.detached`) breaks `PKCanvasView` stroke rendering process-wide — the Pencil stops drawing and existing notes render blank. Device-only; the Simulator and unit tests cannot reproduce it. Render thumbnails via `MainActor.run`. Details: issue #187, PR #189.
- **Don't trust a single on-device OK/NG observation while bisecting**: during the #187 bisect, wrapping `CanvasView` in `GeometryReader` looked like an independent cause, but an isolation build (main + thumbnail fix only) drew fine — the observation was flaky. Before shipping a fix, back each suspected cause with an isolation build that adds/removes only that element.
- **`PKDrawing(strokes:)` crashes in the macOS `swift` interpreter**: PKReplicaManager touches CFPreferences and crashes when a drawing with strokes is created from a script. When seeding note files from macOS, use an empty `PKDrawing()` — thumbnails come out blank, but that is enough to exercise the list pipeline.

## iCloud / UIDocument

- **`NoteDocument`'s conflict resolution is not unit-testable on iOS**: `NSFileVersion.addOfItem(at:withContentsOf:)` — the only API that fabricates file versions — is macOS-only, so iOS tests cannot create conflicting versions locally. Verify conflict handling with two devices syncing over real iCloud. Background: issue #196, PR #197.

## SwiftUI

- **Alerts attached below a `fullScreenCover` never show while the cover is up**: `NoteListParentView` has `.alert(isPresented: $noteStore.showAlert)`, but while `CanvasView` is presented via `.fullScreenCover`, that alert is not displayed. Do not refactor cover-side errors onto the store's `showAlert`/`alertType` pattern — errors shown on top of a cover must live in a view-local `@State` + `.alert` inside the cover. The store alert pattern is for the list screens only. Background: PR #186 review.

## Xcode / build

- **`-destination` needs the `platform=iOS Simulator,` prefix**: without it, destination resolution is flaky ("Unable to find a destination" appears intermittently).
- **Xcode 26.6 (iOS 26.5 SDK) fails asset catalog compilation without the matching simulator runtime**: actool's `CompileAssetCatalogVariant thinned` step always fails when the iOS 26.5 simulator runtime is not installed, even though Swift compilation succeeds. Fix: `xcodebuild -downloadPlatform iOS` (~8.5 GB).
- **Checking out commits older than mid-2026 loses the shared scheme**: `PiecesOfPaper.xcodeproj/xcshareddata/xcschemes/PiecesOfPaper.xcscheme` was untracked (excluded by `.gitignore`) until July 2026. Checking out an older commit (e.g. tag 3.3.0) leaves Xcode with "No Scheme". Recover with `git show <newer-commit>:PiecesOfPaper.xcodeproj/xcshareddata/xcschemes/PiecesOfPaper.xcscheme` — the target IDs are unchanged. When switching back, delete the now-untracked scheme first or it blocks the checkout.
- **The bundle ID is `Individual.LikeAPaper`**, kept from the app's previous name. Anything keyed by bundle ID (simulator `defaults`, app containers) uses this, not `PiecesOfPaper`.

## project.pbxproj

- **Never match pbxproj lines by substring when editing with a script**: a filter on lines containing `SettingViewModel.swift` also matched `ListOrderSettingViewModel.swift` and deleted it. Match exactly, by object ID or by the `/* Foo.swift */` comment form.
- **Verify pbxproj edits with a clean build**: an incremental build can hide a file dropped from Sources behind a stale swiftmodule.
- **Object IDs look sequential but have gaps**: IDs of the form `A700000000000000000000XX` skip values that are already in use. Before assigning a new one, confirm it is unused with `rg`.
- **Pass `-project` as an absolute path in worktree sessions**: both the main checkout and worktrees contain `PiecesOfPaper.xcodeproj`, and the shell cwd can silently revert to the launch directory, making xcodebuild build the wrong tree — especially dangerous for background runs.
- **Re-check object-ID uniqueness after merging main into a branch with hand-added pbxproj objects**: two branches can pick the same "unused" `A700...XX` IDs in parallel (PR #192 and PR #193 both took 51/61). Git merges the text cleanly, but duplicate IDs make Xcode refuse to open the project ("The project is damaged"). After the merge, list duplicate definitions with `rg -o '^\t\t(A[0-9A-F]{24})' -r '$1' project.pbxproj | sort | uniq -d` and renumber your side — published main keeps its IDs. Background: PR #193.

## QuickLook extensions

- **A data-based preview provider must conform to `QLPreviewingController`**: subclassing `QLPreviewProvider` and implementing `providePreview(for:)` is not enough — without the conformance the method is never exposed to the Quick Look host, and the extension loads but silently shows the generic icon. The Xcode template includes the conformance; keep it. Background: PR #193.
- **Cap preview renders by total pixels, not longest side**: on device, ~3.4M-pixel renders were jetsammed in the preview extension while ~1M-pixel renders survived. A longest-side cap lets screen-sized unexpanded drawings through at full display scale, making exactly those notes the largest bitmaps — they failed while bigger expanded canvases (scaled down by the cap) succeeded. `PreviewProvider` caps total pixels at 2M. Diagnosis pattern: thumbnails OK + preview shows the generic icon + failures cluster by drawing size ⇒ render cost, not decode. Background: PR #193.
- **Off-main `PKDrawing.image` is safe inside the QuickLook extensions**: the #187 process-wide breakage requires a `PKCanvasView` in the same process; the extensions have none. Do not "fix" their off-main rendering. Background: PR #193.
