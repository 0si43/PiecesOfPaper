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

### 2026-07-27

- [x] Document the Observation and idb findings from the What's New work (issue #324, PR #326)
  - An optional stored property under `@Observable` fires `didSet` from `init`, so the store's usual persist-in-didSet shape re-persists on every launch — recorded in GOTCHAS with `test_init_readsValuesWithoutRePersisting` named as the guard
  - `idb ui describe-all` returns nothing from inside the sidebar; `describe-point` returns the row with its whole label, which is how the unread marker was asserted in both directions
  - Sidebar pages are reachable in three taps on the shipping build, so the throwaway-build advice is now the fallback rather than the default
  - `defaults read` reports a key as missing even after the app that wrote it has terminated; the container's preferences plist is the reliable read
- [x] Record the pitfalls found during the release check (issue #325, PR #327)
  - `docs/GOTCHAS.md`: `#available` is a runtime check and does not conjure the API — the iOS 26
    close button compiled locally on Xcode 26.6 and failed CI, whose `macos-15` image defaults to
    Xcode 16.4 (issue #320); an `.alert` message drops `Image` interpolation; a multi-line string
    literal keeps the indentation its closing delimiter does not cover (issue #309)
  - `docs/SIMULATOR_E2E.md`: a simulator's preference domain survives `simctl uninstall`, so a
    later `defaults write` brings back every key cfprefsd was holding and a "fresh install" check
    starts with flags the app should never see
  - `CLAUDE.md`: a Scope section on where the maintainer draws the line between a wording defect
    and code for a rare state
- [x] Add an in-app What's New page that accumulates release highlights (issue #319, PR #323)
  - The page, not a launch modal: a sheet at the root would sit under the blank canvas `fullScreenCover` that `sceneDidBecomeActive` opens, the same failure as the alert entry in GOTCHAS
  - `ReleaseNote.all` is the newest-first source for both the page and the unread marker; the shipped `MARKETING_VERSION` is deliberately not consulted, so a patch release with no entry raises no marker
  - `PreferenceStore.hasUnseenWhatsNew(latestVersion:)` takes the version as an argument rather than reading `ReleaseNote.all`, keeping the Store's Model access on the repository path and the rule testable against orderings the shipped list does not contain
  - The seen marker is written by `markWhatsNewSeen(version:)`, not a `didSet`: an optional stored property is initialized to `nil` before `init` runs, so under `@Observable` the seeding assignment counts as a mutation and re-persists on every launch (`test_init_readsValuesWithoutRePersisting` caught it)
  - `SectionHeader` and `Bullet` left `TutorialView` for shared files so both pages share one style

### 2026-07-26

- [x] Add an in-app appearance setting: System / Light / Dark (issue #262, PR #264)
  - `PreferenceStore` ownership moved up to `PiecesOfPaperApp` as `@State`, so all scenes share one instance instead of each iPad window holding its own
  - `.preferredColorScheme` is attached in `RootSplitView`, not the App's `Scene` body: reading the store from a `View` body is what guarantees Observation re-evaluates it
  - `ThumbnailCache` renders under an explicit interface style and keys on it; the previous ambient-trait render could put dark ink on a dark tile once the app appearance can differ from the system's
  - Tag chips pinned to a light base with black text, and the tutorial callout given a dynamic colour via the new `View/Color+App.swift`
  - The shared note image now fills white before drawing, like the QuickLook and Thumbnail extensions already did: `PKDrawing.image` leaves the background transparent, so a viewer in dark mode composited it on black and the dark ink disappeared
- [x] Name the note in the share sheet header instead of showing "PNG image" (issue #270, PR #264)
  - The image is wrapped in a `NoteShareItemSource`; metadata used to hang off a second item whose `itemForActivityType` returned nil, so iOS described the remaining bare `UIImage` by its type
  - `LPLinkMetadata.iconProvider`, not `imageProvider`, is what puts the drawing in the header. The iPad popover form of the sheet shows no icon either way
- [x] Show the canvas controls on launch as a floating overlay (issue #263, PR #265)
  - Both bars are pinned to a constant (status bar hidden, navigation bar hidden) so the top safe-area inset never changes and the drawing no longer shifts when the chrome is toggled; the issue's proposal to pin the status bar visible was dropped to keep the canvas full-bleed and avoid status-bar-tap scroll-to-top
  - `PKCanvasViewWrapper` takes the initial tool picker visibility as an init parameter and defers `becomeFirstResponder()` one runloop turn — `makeUIView` runs before SwiftUI installs the view
  - Done is now reachable from `idb ui tap`, which lifts the SIMULATOR_E2E limitation that needed the un-injectable two-finger tap
  - Also fixed: the unsaved-changes alert left the tool picker hidden when cancelled or when Save failed
- [x] Route the canvas preference reads through PreferenceStore (issue #269, PR #280)
  - `PKCanvasViewWrapper` takes the autosave and infinite scroll flags as closures alongside `saveAction`; `CanvasView` supplies them from `@Environment(PreferenceStore.self)`, capturing the store explicitly so the read is not a frozen `@Environment` copy. Closures rather than `Bool`s because the empty `updateUIView` freezes `Coordinator.parent`
  - `MainActor.assumeIsolated` turned out to be unnecessary: `PKCanvasViewDelegate` is `NS_SWIFT_UI_ACTOR`, so `canvasViewDrawingDidChange` is an isolated witness. Both preference reads had to move into it because the private `updateContentSizeIfNeeded` helper is not a witness and inherits no isolation
  - First tests over the autosave gate (`PKCanvasViewWrapperTests`), including the value changing after the coordinator was made; confirmed to fail against a probe that freezes the flags at init
- [x] Get SwiftLint back to zero violations (issue #306, PR #307)
  - 12 violations across 6 files, all resolved without touching `.swiftlint.yml`
  - `file_name` wants `Type+Anything.swift` for an `extension Type` (default
    `suffix_pattern` is `\+.*`); a test file named after its own type must *not* gain a
    `+`, or the stripped name stops matching
  - Splitting `NoteStore` did not require exposing the index setters: index writes go
    through `upsertEntry(_:in:)` / `removeEntryFromIndexes(_:)` in `NoteStore.swift`, so
    `inboxIndex` / `archivedIndex` keep `private(set)`. Taking a `NoteDirectory` instead of
    an `inout` array also removed three `switch directory` statements at the call sites
  - `discouraged_optional_boolean` is silenced in place with a `disable:next` comment rather
    than reworked: `lastFetchUsedCloudStorage: Bool?` is a genuine tri-state (never fetched /
    cloud / local) and `Bool?` reads better there than a three-case enum. No logic changed
  - Test-suite splits were verified by diffing test-case names from the `.xcresult` bundles,
    not the console log — swift-testing output interleaves and garbles lines, which made
    four tests look like they had disappeared from a run that was in fact identical
  - The three reusable pitfalls from this work (cross-file `private(set)`, the `file_name`
    suffix rule and its inverse trap, reading test names from `.xcresult`) are written up in
    a new "Swift / SwiftLint" section of [docs/GOTCHAS.md](../GOTCHAS.md) and under
    "Xcode / build". Both claims about lint behaviour there were probed before being written
    down; a first draft asserted that `internal(set)` trips
    `redundant_set_access_control` here, which turned out to be false
- [x] Record the FilePath layering exception instead of resolving it (issue #308, PR #310)
  - `docs/GOTCHAS.md` gains an "Architecture / layering" section: the one-way View + Store +
    Repository + Model rule, plus why `FilePath.isiCloudActive` building a
    `PreferenceRepository()` inline is accepted. It closes a `Model → Repository → Model` cycle
    with `NoteRepository`/`TagRepository`, but `FilePath` is an `enum` of argument-less statics
    reached from pure value types and tests, so parameterizing it by storage mode touches
    roughly thirty call sites, and the pull-based read cannot go stale
  - The accepted costs are written down too: tests that derive URLs from `FilePath.inboxUrl`
    depend on whatever the flag returns in the test process, and `savingUrl` /
    `noteMetadataCacheFileUrl` resolve it separately, so the cache filename suffix and the
    directory in use are not atomic
  - Contrast with the canvas equivalent (issue #269, PR #280) is recorded: that fix was cheap
    only because `PKCanvasViewWrapper` already took closures from the SwiftUI side
- [x] Document the two idb limits found while verifying finger drawing (issue #285, PR #286)
  - The tool picker's ⋯ popover ignores idb taps although `describe-all` lists its rows; drive "Only Draw with Apple Pencil" through `com.apple.UIKit` / `UIPencilOnlyDrawWithPencilKey` instead, with the `strings` recipe for finding such keys in the runtime's UIKitCore
  - The first gesture after a menu opens is spent dismissing it, which reads as "drawing is broken" unless state is asserted before and after each injection
- [x] Document the share/export, simulator defaults, and pbxproj pitfalls from PR #264 (issue #274, PR #275)
  - New "Sharing / export" section in GOTCHAS: `PKDrawing.image` renders on a transparent background, `LPLinkMetadata.iconProvider` vs `imageProvider`, and metadata having to ride on the item it describes
  - `defaults write` in SIMULATOR_E2E only lands before the app has written that key itself; afterwards cfprefsd holds the domain and what the app displays is the truth
- [x] Make existing tags editable from the tag list (issue #266, PR #279)
  - The creation sheet body moved into `TagEditorView`, shared by add and edit; the draft now
    lives per presentation, which also fixed the add sheet reopening pre-filled with the
    previous value
  - `TagStore.update(_:)` drops an edit whose id is gone rather than re-adding it, so a
    deletion synced from another device is not undone
  - `TagEntity`'s `==` was id-only, which made SwiftUI skip the re-render after a rename: the
    new name reached `taglist.json` but not the screen. Equality is memberwise now, and
    `TagStore.remove(_:)` / `filteringTags(from:)` / `nonFilteringTags(from:)` and the filter
    chip in `ListOrderSettingView` compare `.id` explicitly. This also makes the stale
    `ListOrder.filterBy` copy inert instead of relying on the lying `==`
  - `CodableUIColor.opaqueColor` seeds the `ColorPicker`; `swiftUIColor`'s hardcoded `0.7` is
    how the capsule is drawn, not what the user picked, and round-tripping it would write the
    fade into the stored `alpha`
  - Found by Simulator verification, not by the unit tests — the store tests passed while the
    rename was invisible on screen
- [x] Let a finger draw on iPad by leaving `drawingPolicy` at `.default` (issue #271, PR #281)
  - The issue's "add a hide-the-chrome button" step was dropped for the opposite rule: when a finger draws, paper-only mode is not offered. `.default` degrades to pencil-only whenever the tool picker is hidden, so a button would drop finger users into a mode with no usable input — `tapGesture` guards the entry instead, and GOTCHAS records why the button must not come back
  - `showsDrawingPolicyControls` back to its default `true`, which puts a Draw with Finger switch in the picker's ⋯ menu; note it writes the systemwide Settings > Apple Pencil value, not an app preference
  - Pencil double tap now restores panel and picker together via a one-way `onRevealUI` closure — a toggle would flip into paper-only mode when delivered while the Share sheet or unsaved alert has the picker hidden
  - The Simulator keeps its `.anyInput` override, verified to still win over the system setting so E2E drawing stays deterministic; the guard itself was exercised in both directions with a temporary button, and the Draw with Finger row was confirmed absent on a `origin/main` baseline build
- [x] Move three iOS-specific facts from the machine-local rulebook into the repository docs (issue #283, PR #284)
  - Touch consumption vs. the exit path, and SwiftUI's undeclared alert buttons, go to `docs/GOTCHAS.md`; the `osascript` dead end goes to `docs/SIMULATOR_E2E.md` Limitations
  - Found with `/doctor`: the facts lived only in `~/.claude/CLAUDE.md`, so they were invisible in review and sat far from the entries they belong next to
  - The general review habits stay in the personal rulebook — only the project-specific facts moved
- [x] Document -only-testing zero-match pitfall with swift-testing (issue #260, PR #261)
  - Function-level `-only-testing` filters can run zero tests and still report TEST SUCCEEDED; filter at suite level and check the `✔ Test run with N tests` count
- [x] Raise the deployment target to iOS 18 and clear the deprecations it surfaces (issues #297, #292, #298 and #299, PR #295)
  - The pencil double tap moves to `pencilInteraction(_:didReceiveTap:)`. That callback is iOS 17.5+ while the floor was 17.0, so raising the floor first made it a straight replacement instead of an `@available` pair, and the deprecated `pencilInteractionDidTap(_:)` is gone
  - The bump surfaced 7 more deprecation warnings, all cleared here: `PKToolPicker.selectedTool` → `selectedToolItem` (5) and `SKStoreReviewController` → `AppStore.requestReview(in:)` (2). Build is back to 0 deprecation warnings
  - Tool tracking now holds `PKToolPickerItem` rather than `PKTool`, because the two APIs that would keep it tool-shaped — `PKToolPickerItem.tool` and `PKToolPicker.defaultToolItems` — are iOS 26+
  - **Behaviour change**: opening a canvas selected the pen *and* forced black at width 1; `selectedToolItem` can only select, so the pen now keeps the colour the picker restored. Confirmed by running the same idb sequence on builds either side of the change: after choosing red, closing and reopening draws black on the old build and red on the new one. A fresh install is unchanged — the default pen item is already black at width 1.0
- [x] Rebuild NoteInformationView on Grid so its two columns stay aligned (issue #267, PR #276)
  - The hand-built `HStack` of two `VStack`s let the Tags row (`TagHStack` at `minHeight: 60`)
    grow the right column only, drifting every separator below it
  - Separators are now `Divider()`s directly in the `Grid`, spanning all columns, so the
    `#if DEBUG` ID row no longer has to keep per-column `Divider()` counts in sync by hand
  - Vertical column divider dropped; the label column is `.foregroundStyle(.secondary)` instead
  - Popover sizing (`CanvasView`) deliberately untouched — its width still tracks the tag count
- [x] Bump the version to 4.0.0 and the build number to 30 for the App Store submission (issue #303, PR #304)
  - Build number jumps 18 → 30 because App Store Connect's last uploaded build is 29; the value tracked in the repository had drifted from what was actually shipped
  - `scripts/bump-version.sh` rewrites every build configuration in one pass, keeping the app and both QuickLook extensions on the same version and build
  - 4.0.0 rather than 3.4.0: the minimum iOS goes 17.0 → 18.0, and notes are renamed `.plist` → `.pop`, which hides them from a device still running 3.3.0 against the same iCloud container until that device is updated
- [x] Explain once why tapping no longer hides the canvas controls (issue #302, PR #305)
  - `CanvasView` shows a one-time alert on iPad while `UIPencilInteraction.prefersPencilOnlyDrawing`
    is false, so people updating from 3.3.0 — which forced `.pencilOnly` and always had the tap —
    learn that finger drawing and the tap-to-hide gesture are exclusive
  - The app cannot change the setting itself: `prefersPencilOnlyDrawing` is a read-only class
    property, so the alert spells out the two steps through the tool picker's ••• menu
  - A tooltip on that menu button is impossible: `PKToolPicker.frameObscured(in:)` returns
    `CGRect.null` for the movable iPad palette, and a popover anchored to `accessoryItem` lays
    over the palette with no arrow. `Text` also drops `Image` interpolation in an alert message
- [x] Drop the indentation the archive confirmation inherited from its literal (issue #309, PR #305)
  - A multi-line string literal indented deeper than its closing delimiter keeps the difference,
    so the message began with four spaces
- [x] Correct the app's user-facing English (issue #311, PR #305)
  - `archived` where the infinitive belongs, `1 notes`, `note(s)`, `Select tag which you want to
    add`, `Github`, missing articles, and title-case inconsistencies across the sidebar, settings,
    sort sheet and tutorial
  - `ListOrder` gained a `label` property the way `AppearanceMode` has one, because its raw values
    are the persisted sort setting; `ListOrderTests` pins them
- [x] Read a list row's tags without requiring the dates to match (issue #312, PR #305)
  - `tagIds(for:)` went through `validMetadata`, which compares the metadata cache's date with the
    index entry's. On iCloud those come from different sources — the cache from the local file the
    write-back stamped, the entry from the `NSMetadataQuery` — so an enumeration landing between a
    tag edit and the next render emptied a row whose tags were on disk
  - The date still gates the thumbnail and the hydration pass, which is what it actually answers
- [x] Give the tag sheet a header with a close button (issue #314, PR #305)
  - `AddTagView` wraps itself in a `NavigationStack` with a title and Done, the way `TagEditorView`
    already does; before it, the only way out was a tap outside the card
- [x] Close the tag and sort sheets with a close control instead of Done (issue #316, PR #305)
  - Both sheets apply their changes as they are made, so the trailing button only dismisses.
    `SheetCloseButton` holds the runtime branch: `ButtonRole.close` from iOS 26, an `xmark` before
    it — a declaration `@available` would have taken the fallback down with it
  - `TagEditorView` (commits a draft) and `CanvasView` (can raise the unsaved-changes alert) keep
    their Done labels
- [x] Bring the tutorial and the archive wording in line with the app (issue #317, PR #305)
  - Dropped three passages the app has outgrown: the claim that iCloud notes need the Files app to
    download (PR #192 lists them and `NoteRepository.open` starts the download), the Important Notes
    callout about hanging past ~500 files (the index opens no documents; the known hang went in
    PR #208), and "double-tapping the Apple Pencil switches to eraser" (the handler follows
    `UIPencilInteraction.preferredTapAction`)
  - The tutorial section, the bulk-move confirmation and the note information row now say Trash,
    the name the sidebar and the menu use. `Color.calloutBackground` went with the callout
- [x] Name the split view column after the pages it lists (issue #318, PR #305)
  - `RootSplitView.sideBarList` → `pageList`: the column is pushed as a full screen in a compact
    size class, so it is only a sidebar on iPad, and SwiftUI spells sidebar as one word anyway
- [x] Run the CI tests on an Xcode that has the iOS 26 SDK (issue #320, PR #305)
  - `#available(iOS 26.0, *)` is a runtime check, so `SheetCloseButton` still needed `ButtonRole.close`
    in the SDK it compiles against. The `macos-15` image defaults to Xcode 16.4, and the workflow now
    selects the newest `Xcode_26*.app` and fails loudly when the image carries none
- [x] Count what the bulk move touches, not what the filter shows (issue #322, PR #305)
  - The confirmation counted `displayEntries(for:)`, which the tag filter narrows, while
    `allArchive()` / `allUnarchive()` pass the whole index to `moveAll` — with two of fifty notes on
    screen it asked about two and moved fifty
  - `NoteStore.entryCount(for:)` answers the unfiltered count and the message says "all N notes", so
    the number cannot be read as the visible subset
- [x] Trim five comments that only restate the code (issue #277, PR #278)
  - Audited all 508 comment lines in 58 Swift files; the Why-not convention was already followed almost everywhere, so only five comments qualified
  - Left doc comments whose first sentence restates the declaration but whose later sentences carry the why: the first sentence is the Xcode Quick Help summary line
- [x] Present the share sheet from UIKit so iPad gets a popover instead of a narrow column (issue #268, PR #282)
  - `UIActivityViewController` was the content of a SwiftUI `.sheet`, so iPad embedded it in a form-sheet container instead of letting it present itself
  - New `ShareSheetPresenter` attaches an empty view controller with `.background` at the share trigger; it presents the activity controller and doubles as the popover's `sourceView`
  - Canvas anchors to the share button and restores the tool picker from `completionWithItemsHandler`; the note list anchors at screen level with `permittedArrowDirections = []`, because its context menu has closed by the time the note finishes loading and a cell anchor can be removed by a refresh or archive
  - `ShareLink` was the issue's original proposal and was rejected: the note list opens its document asynchronously (a `Transferable` closure is `Sendable`, cannot reach `NoteStore`, and would swallow the download-failure alert), and on the canvas `ShareLink(item:)` would rasterize the drawing on every autosave-driven body evaluation
  - Anchoring only in a regular size class: `UIActivityViewController` returns a popover controller in compact too, and configuring it downgraded iPhone to an anchored card. Found by comparing against a build of the previous commit on the same simulator
  - Deleted `UIActivityViewControllerWrapper`; `NoteListPresentation` and `NoteGridView` untouched, so the existing share tests remain the regression guard
- [x] Update SIMULATOR_E2E.md with PR #248 verification findings (issue #258, PR #259)
  - Long press is `idb ui tap --duration` (same-point swipe does not fire); screenshots via `xcrun simctl io` (`idb screenshot` can fail); stale `NoteListParentView` reference corrected to `NoteListScreen`
  - New section on seeding notes/tags into the app container from macOS, with the dedicated-simulator caveat for parallel sessions
- [x] Record the idb tap duration trap and two canvas verification limits (issue #290, PR #291)
  - A zero-duration `idb ui tap` misses SwiftUI controls silently, and a `ui swipe` outside the drawable area adds no stroke while still reporting success — the latter nearly turned "nothing was saved with autosave off" into a false pass during #269
  - Limitations gained `PKCanvasView.contentSize` (no scroll view in the accessibility tree) and the fact that preferences cannot be changed while the canvas is open
- [x] Document that the first idb gesture after launch is dropped (issue #300, PR #301)
  - A `ui swipe` right after `simctl launch` draws nothing although `describe-all` already lists the chrome, and two swipes in one shell command are both lost; the retry has to be a separate injection
- [x] Document data-container re-seeding and per-note popover capture in SIMULATOR_E2E (issue #287, PR #296)
  - `simctl install` swaps the data container even with no parallel session, so the seed
    has to come after the final install with the path re-queried
  - `openurl` + a tap on the launch-visible control panel captures a chosen note's info
    popover; used for the four states in issue #267
- [x] Document the partial-equality SwiftUI trap and two idb facts (issue #293, PR #294)
  - `docs/GOTCHAS.md`: a value type whose `==` compares only part of its fields makes SwiftUI
    skip the re-render — the `TagEntity` id-only `==` behind PR #279, with the four call sites
    that now compare `.id` explicitly
  - `docs/SIMULATOR_E2E.md`: `idb ui text` goes through the simulator's active keyboard, so a
    device created on a Japanese Mac turns `"renamed"` into `れなめd`; and the "Sidebar pages"
    bullet was wrong that no blank note opens — it does, on both iPhone and iPad, and tapping
    Done is what reveals the chosen page

### 2026-07-25

- [x] Limit blank-note auto-open to cold launch and long background resume (issue #252, PR #253)
  - scenePhase handling consolidated into RootSplitView; NoteStore gates openBlankNoteIfIdle with a 30-minute background threshold (injectable clock, unit-tested)
- [x] Clean up duplicated code, deprecated APIs, and stale imports (issue #221, PR #248)
  - Merged `DeletableTag` into `Tag` (a `deletable` parameter) and folded `NoteListTagHStack` into `TagHStack`; the strip's frame and whole-strip tap moved to call sites, and the per-tag tap gesture attaches only when an action is provided so a caller's whole-strip gesture is not swallowed
  - Extracted the duplicated share-image rendering into `PKDrawing.lightModeImage(scale:)`, `@MainActor` so the #187 off-main-rendering invariant is compiler-enforced
  - Guarded `NoteData.createTestData()` and its three `#Preview` call sites behind `#if DEBUG` (`#Preview` bodies compile in Release); verified via `nm` the symbol is absent from the Release binary
  - `LegacyNoteMigrator` move/download failures are now logged via `Logger.legacyNoteMigrator` instead of `try?`; retry-next-pass semantics unchanged, no alert (fires every enumeration). Initially `print`, switched to `os.Logger` after PR #246 landed the convention mid-flight
  - The NavigationView → NavigationStack item was found already complete (zero occurrences)
- [x] Document SwiftLint workflow in CLAUDE.md (issue #249, PR #250)
  - Lint before each commit (opt-in rules cover tests too); xcodebuild's SwiftLint autocorrect phase can rewrite sources, so check git status after builds
- [x] Harden the note save lifecycle against silent data loss (issue #225, PR #251)
  - Chose hardening over the issue's live-UIDocument proposal: new notes cannot be opened before creation (GOTCHAS: open() on a missing file waits forever), and the bug is not locally reproducible
  - Identified mechanism: `FilePath.iCloudUrl` cached only non-nil resolutions, so a late-resolving container flipped `savingUrl` mid-session and `applySaved` silently dropped the note from the index; the cache now holds nil too and re-resolves only via the new ubiquity-change/foreground observer
  - `NoteRepository.save` is now async throwing: creates missing parent directories, verifies a non-empty file exists after the write, surfaces the reason captured by a new `UIDocument.handleError` override, and logs all failure branches via `os.Logger` for field diagnosis
  - `applySaved` falls back to folder-name classification (with a warning log) instead of hiding notes saved into a foreign container; `open()` fails fast for missing non-ubiquitous files instead of waiting forever
- [x] Improve iCloud error handling and fallback visibility (issue #224, PR #254)
  - New `CloudAvailability` model (userDisabled / signedOut / driveUnavailable / available) with injectable `UbiquityStatusProviding`; `FilePath.isiCloudActive` and `PreferenceStore` both derive from it
  - `FilePath` now caches the absent container URL too (`URL??`) so the storage mode cannot flip mid-operation; `revalidateiCloudUrl()` on scene activation is the only mid-session refresh
  - Kept the no-fetch policy on availability alerts but fixed the latent endless-spinner bug (`isLoading` never cleared on the alert path)
  - Download failures (`fileNotDownloaded` via `ubiquitousItemDownloadingStatus`) now surface as a network hint, split from the corrupt-file message
  - Degraded-mode `icloud.slash` toolbar indicator + Settings footer; one-time alert on mid-session cloud→local fallback (user-initiated switch stays silent)
- [x] Improve accessibility labels, error visibility, and logging (issue #222, PR #246)
  - Note thumbnail VoiceOver label is now "Note, \<updated date\>[, tags: ...]" instead of a bare "Note"; tag names are passed in from NoteGridView, which already resolves them for NoteListTagHStack
  - New Logger+App.swift: os.Logger with subsystem Individual.LikeAPaper and per-type categories; all 6 print() error logs replaced. Error descriptions logged with privacy: .public (file-operation errors only, never note content)
  - FilePath.makeDirectoryIfNeeded logs creation failures instead of try?; signature stays non-throwing (sole caller is a didSet observer) and withIntermediateDirectories stays false so a missing parent surfaces in the log
- [x] Improve readability of the Quick Tutorial page (issue #243, PR #247)
  - Rebuilt `TutorialView` from one multi-line `Text` literal into section headers (`Label` + SF Symbol), real bullet rows, and FAQ question/answer pairs, all as private views in the same file
  - Column capped at 720pt and centered in the split-view detail pane; "Important Notes" styled as a tinted callout
  - Copy cleanup only: `Basis` → `Basics`, actual Setting toggle names spelled out, overloaded bullets split, dangling nested Archive item folded into its parent
  - The issue's proposed `Bullet` `level` parameter was dropped as dead code — no nested bullets remain after the copy cleanup
- [x] Surface bulk archive/unarchive failures and coalesce overlapping fetches (issue #220, PR #257)
  - Bulk moves continue past per-note failures and throw an aggregate `bulkMoveFailed(count:)`, presented via the existing list alert
  - `NoteStore.fetch` dedupes concurrent same-directory enumerations with an `inFlightFetches` task map (same pattern as `inFlightLoads`)
  - Issue item on `refreshable { Task { ... } }` was already resolved by 6ac8cf4; no change needed
- [x] Document the initial-selection workaround for reaching sidebar pages in Simulator E2E (issue #255, PR #256)
  - `docs/SIMULATOR_E2E.md` Limitations: a throwaway build with `RootSplitView`'s initial `selection` set to the target page reaches Quick Tutorial / Setting / Tag List directly, lighter than stubbing `openBlankNoteIfIdle()`

### 2026-07-23

- [x] Fix the pbxproj duplicate-ID detection command in GOTCHAS (issue #244, PR #245)
  - The documented `A[0-9A-F]{24}` is 25 chars and matches none of the 24-char IDs, so it always reported no duplicates; corrected to `A7[0-9A-F]{22}`
  - PR #236 shipped a build-breaking collision this way; added a note that renumbering to the next free ID during a merge collides again on the next merge

### 2026-07-22

- [x] Convert the project's four top-level folders to file system synchronized folders (issue #241, PR #242)
  - Source files no longer appear in `project.pbxproj`: adding or removing one produces no diff, which removes the recurring merge conflicts and the parallel-branch object-ID collisions that made the project unopenable
  - `objectVersion` 54 → 77, so Xcode 16 or later is now required to open the project
  - Cross-target sharing of `NoteEntity.swift` / `TagEntity.swift` with the QuickLook extensions is now a membership exception instead of duplicate build-file entries
  - Verified against an unmodified `origin/main` build: identical test results (133 tests in 20 suites), identical per-target source lists, identical app bundle contents
  - Merging PRs #235 and #236, which added and renamed five source files, needed no pbxproj change at all — the resolved project file is byte-identical to the pre-merge one

### 2026-07-21

- [x] Restructure the NoteList view hierarchy and move presentation state out of NoteStore (issue #219, PR #235)
  - Sheet/alert state moved from `NoteStore` to a screen-owned `NoteListPresentation`, so modal state is per-screen instead of app-global
  - `NoteStore` reports failures by throwing: `delete` is `throws`, `duplicate`/`addTag`/`removeTag` are `async throws`, with the completion-based repository calls wrapped in `withCheckedContinuation`
  - Four layers became three, named by role: `NoteListParentView` → `NoteListScreen`, `NoteListView` → `NoteGridView`, `NoteView` → `NoteThumbnailView`; the nested `NoteScrollView` was folded into the grid
  - `openedNote` and `showExternalOpenAlert` stayed on `NoteStore` — `openedNote` is shared by three entry points and its security-scope lifecycle lives in the store
  - `AddTagView` presents its own alert: one raised by the screen behind it would be covered by the sheet
  - Several #219 proposals were already resolved on main before this work (single `fullScreenCover` via `openedNote`, `.refreshable` awaiting directly, `showCanvasView` removed)

### 2026-07-20

- [x] Harden CI against the empty simulator device-list flake (issue #211, PR #212)
  - `test.yml` waits for `simctl` to list the target device, logs the device list, and retries `xcodebuild test` up to 3 times — but only when the failure log matches the placeholder-only destination signature, so genuine test failures still fail fast
  - Flake signature and remedy recorded in docs/GOTCHAS.md
- [x] Run note file operations and the tag list through NSFileCoordinator (issue #201, PR #236)
  - `CoordinatedFileAccess` wraps the asynchronous `NSFileAccessIntent` API, so a stalled iCloud sync never blocks a thread; moves coordinate both URLs and bracket the rename with `item(at:willMoveTo:)` / `item(at:didMoveTo:)`
  - Repository methods became `async`; the stores keep synchronous signatures and drive them from an internal `Task`, so no view code changed
  - Going asynchronous opened two windows that are closed explicitly: a single task chain per store serializes operations, and `pendingFileOperationUrls` keeps a file whose operation is in flight out of enumeration results so a mid-operation refresh cannot resurrect it
  - Index updates are optimistic and roll back on failure, so `NoteStoreError.moveFailed` was added — archive/unarchive now alert instead of only printing
  - `LegacyNoteMigrator` stays uncoordinated on purpose: it runs synchronously on the main actor inside enumeration
- [x] Document the swift-testing log line and the `.git-blame-ignore-revs` upkeep rule (issue #230, PR #231)
  - `xcodebuild test` always prints `Executed 0 tests, with 0 failures` for this suite because it uses swift-testing; the real count is on the `✔ Test run with N tests in M suites passed` line
- [x] Make the empty note list refreshable with pull-to-refresh (issue #213, PR #229)
  - `Text("No Data")` → `ContentUnavailableView` inside a `ScrollView`; `.refreshable` only exposes the gesture in a scrollable container
  - Verified with idb: dropping a `.pop` into `InboxFolder` while the empty state is on screen, then pulling down, loads it
- [x] Fix NoteDocument conflict resolution to actually keep the newest version (issue #200)
  - `resolveConflictIfNeeded()` claimed "later wins" but unconditionally kept the local
    current version; it now promotes the newest of current + unresolved conflict versions
    via `NSFileVersion.replaceItem(at:)` before removing the others.
  - The pick-newest decision is factored into `NoteConflictResolver.newestVersionIndex`
    (plain `Date?` values) because conflict versions cannot be fabricated in iOS unit
    tests; ties favor the current version so no needless file replacement happens.
  - End-to-end conflict verification still requires two physical devices producing a
    real iCloud conflict.
- [x] Document fragment PR-number ordering in docs/progress/README.md (issue #214, PR #215)
  - Push code commits first, create the PR, then commit the fragment with the number from the `gh pr create` output URL
- [x] Document the test module name and pbxproj ID-gap prevention in GOTCHAS (issue #226, PR #227)
  - `@testable import` needs `Pieces_of_Paper`, not the target/project name; cost a build cycle during PR #210
  - The existing duplicate-ID entry now carries the prevention that worked in PR #210: start a branch's IDs above main's highest
- [x] Document pitfalls surfaced by the Files-app open work (issue #217, PR #218)
  - GOTCHAS: `UIDocument.close()` after a failed `open()` hangs forever; `open()` on a missing file waits for an iCloud download by design (test the failure path with a corrupt file); a test-runner "Restarting" line with no `.ips` and a minutes-long gap is a hang, traceable via UIDocumentLog
  - GOTCHAS: `fullScreenCover`/`sheet` content only inherits environment values injected outside the attachment point — attach presentation modifiers inside the `.environment` chain
  - SIMULATOR_E2E: `simctl openurl` with a `file://` URL exercises the `onOpenURL` document-open path without automating the Files app
- [x] Lazy-load the note list from a metadata index instead of retaining every PKDrawing (issue #204 Phase A, PR #210)
  - NoteStore now holds NoteIndexEntry (URL + dates from enumeration) per note; documents open per cell on appearance, render the thumbnail, and discard the drawing, so memory stays bounded by visible cells + the NSCache
  - createdDate parses from the filename timestamp (new FilePath.parseTimestamp), updatedDate comes from fs contentModificationDate (URLResourceValues locally, NSMetadataQuery attributes for iCloud incl. undownloaded items)
  - Tags live inside the plist, so an active tag filter hydrates metadata in the background (width-4 opens, drawings discarded); Phase B (persistent metadata cache) is a follow-up
  - Behavior changes: canvas open is open-then-present (one document open on tap), tagging now bumps the updated-date sort key (fs modDate), the aggregated "Failed to load N note(s)" alert on fetch is gone (per-cell retry on reappearance)
- [x] Normalize tag storage so notes reference tags by id (issue #203, PR #232)
  - `NoteEntity.tags: [TagEntity]` became `tagIds: [UUID]`; decoding accepts the legacy embedded-copy format and encoding writes the new key only, so notes migrate on their next save
  - Tags embedded in a legacy note are restored into `taglist.json` only while the tag list is empty; adopting them unconditionally would resurrect deleted tags every time an unmigrated note is opened
  - `TagEntity.name`/`color` are now `var`, making rename/recolor a `TagStore` edit that applies to every note (editing UI is a follow-up)
  - `ListOrder.filterBy` deliberately stays `[TagEntity]`: a UserDefaults preference whose display already resolves through `TagStore`
- [x] Stop the note list from re-fetching when the tag sheet closes (issue #239, PR #232)
  - The `onDismiss` fetch re-enumerated the just-saved note with its new modification date and invalidated the optimistic metadata until the save landed, making the tag row flicker out; `addTag`/`removeTag` → `save` → `applySaved` already updates the index and metadata, so the fetch was redundant
- [x] Persist the note listing metadata cache locally (issue #204 Phase B, PR #234)
  - Metadata is keyed by note file name instead of absolute URL: container paths change across installs, and file names are microsecond timestamps that survive archive/unarchive moves — which also removed the metadata re-key on move
  - The cache file lives in Caches (never synced) with the storage mode in its name; unknown version / corrupt / missing all load as empty, since the notes themselves are the source of truth
  - Tag-filter hydration awaits the startup read, so a cold start filters from disk and only re-opens notes whose modification date moved
  - No pre-build at launch and no thumbnail persistence: both would reintroduce the library-wide I/O that Phase A (PR #210) removed
- [x] Open the tapped note on the canvas when a `.pop` file is opened from the Files app (issue #198, PR #208)
  - Canvas presentation unified onto a single `fullScreenCover(item: NoteStore.openedNote)` at `SideBarListView`; new note, thumbnail tap, and external open all present by assigning `openedNote`, which removes the onOpenURL vs scenePhase race by construction
  - Security scope for out-of-container URLs is held by the store while the note is open (autosave writes back to the scoped URL) and released on dismissal
  - Foreign files (outside Inbox/Archived) open in place and are never inserted into the note lists
  - Bug fix found by the new tests: `NoteRepository.open` hung forever on unreadable files because `close()` after a failed `open()` never fires its completion handler
- [x] Remove the Xcode default file headers from all Swift files and ban them via SwiftLint (issue #223, PR #228)
  - `file_header` is not a correctable rule, so `swiftlint --fix` cannot strip the headers; the 55 files were stripped with a one-off script after verifying every one matched the template exactly
  - `.git-blame-ignore-revs` added so the 55-file removal commit does not obscure `git blame`
  - `PreviewExtension` / `ThumbnailExtension` are outside `.swiftlint.yml`'s `included:`, so their headers are removed but not enforced
- [x] Rename `SideBarListView` to `RootSplitView` and remove the `RootView` pass-through (issue #216, PR #233)
  - The type is the app's root container (owns the `NavigationSplitView`, the three stores, and the app-wide `fullScreenCover`), not just the sidebar list; `RootView` was an empty pass-through occupying the "Root" name
  - Moved to `View/Root/RootSplitView.swift` so every view lives under `View/`; `PiecesOfPaperApp` calls `RootSplitView()` directly
  - No logic changes — the body is byte-identical apart from the type name, and the presentation modifiers stay inside the `.environment` chain
- [x] Stop `TagRepository.fetchAll` from overwriting the tag list with defaults while the iCloud copy is undownloaded (issue #199, PR #209)
  - `TagListFileState` distinguishes downloaded / in-cloud-only (`.taglist.json.icloud` placeholder) / absent; fetch never writes to disk
  - Defaults get fixed UUIDs and are persisted lazily on the first user edit (id-based `TagEntity` equality would otherwise detach notes from default tags)
  - `saveAll` refuses to write over an undownloaded placeholder, writes `.atomic`, and owns Library-directory creation
  - `TagListCloudMonitor` (NSMetadataQuery on `taglist.json`) reloads `TagStore` when the download lands or another device edits tags
  - Prerequisite for tag-model normalization (#203); residual fresh-install race documented in the PR

### 2026-07-19

- [x] Enumerate iCloud notes via NSMetadataQuery so undownloaded notes stay listed (PR #192)
- [x] Document on-device verification requirement for PencilKit changes (PR #191)
- [x] Render note thumbnails on the main actor to fix broken Pencil drawing on device (issue #187, PR #189)
  - Root cause: off-main `PKDrawing.image` breaks PKCanvasView rendering process-wide, device-only — see docs/GOTCHAS.md
- [x] Remove remaining ViewModels to complete the View + Store + Repository migration (PR #186)
- [x] Set up Claude Code documentation: GOTCHAS.md and the progress log system (issue #194, PR #195)
- [x] Document QuickLook extension and pbxproj merge pitfalls in GOTCHAS (issue #205, PR #206)
  - Parallel-branch pbxproj ID collisions merge cleanly in git but leave the project unopenable; added a post-merge duplicate-ID check
  - QLPreviewingController conformance requirement and the total-pixel render cap came out of the PR #193 device debugging
- [x] Make drawing and storage flows testable in the iOS Simulator (issue #196, PR #197)
  - Simulator builds set `drawingPolicy = .anyInput` so mouse drags draw; device keeps `.pencilOnly`
  - Simulator-only two-finger tap (Option+click) toggles the tool picker / navigation bar, since single taps draw under `.anyInput`
  - Shared `PKDrawing.stub()` test fixture; non-empty drawing plist round-trip covered in NoteDocumentTests
  - `NoteDocument` conflict resolution stays untestable on iOS (`NSFileVersion.addOfItem` is macOS-only) — recorded in docs/GOTCHAS.md
  - docs/SIMULATOR_E2E.md: idb-based command-line E2E workflow (setup, draw injection, describe-all assertions; UI toggle not injectable yet)

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
