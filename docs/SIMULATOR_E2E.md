# Driving the app in the iOS Simulator with idb

How to operate the app end-to-end in the Simulator from the command line using
[idb](https://github.com/facebook/idb) — for Claude Code sessions and other automation
that cannot click the Simulator window. Verified 2026-07-19: drawing via `idb ui swipe`,
persistence via autosave, and stroke-level assertions via `idb ui describe-all` all work.
The one gap is the UI-visibility toggle (see Limitations).

## Setup

Two components. The companion is a one-time install; the client needs a Python <= 3.11
environment.

```sh
# Companion (gRPC server that talks to the Simulator)
brew tap facebook/fb
brew trust facebook/fb        # Homebrew refuses untrusted third-party taps without this
brew install idb-companion

# Client — the PyPI package crashes on Python 3.12+ (asyncio.get_event_loop, facebook/idb#896)
# and the git-main setup.py does not build on 3.14 either. Use a python@3.11 venv:
brew install python@3.11
/opt/homebrew/opt/python@3.11/bin/python3.11 -m venv ~/.venvs/idb
~/.venvs/idb/bin/pip install fb-idb
```

`idb` auto-spawns a companion for local simulators; no separate server process is needed.
`idb list-targets` shows simulators and their UDIDs.

## Launching the app

```sh
UDID=<simulator udid>
xcrun simctl boot $UDID
xcrun simctl install $UDID "<DerivedData>/Build/Products/Debug-iphonesimulator/Pieces of Paper.app"
# Local-storage mode: skip iCloud so all save/load paths hit the local Documents fallback
xcrun simctl spawn $UDID defaults write Individual.LikeAPaper iCloud_disabled -bool YES
xcrun simctl launch $UDID Individual.LikeAPaper
```

The app launches straight into a fullscreen canvas (see "Simulator testing" in
[CLAUDE.md](../CLAUDE.md)); drawing works immediately because Simulator builds override
`drawingPolicy` to `.anyInput`, independently of the system "Only Draw with Apple Pencil"
setting that governs it on device. The canvas chrome is visible from launch — a floating
panel with Note Information, Share and Done in the top-right corner — so those three
are tappable without any gesture injection.

`defaults write` only lands **before the app has written that key itself**. Once the app is
running, cfprefsd holds the domain: an external write does not reach it, and `defaults read`
keeps returning the older on-disk value. Use it to seed initial state, and drive every later
change through the app's own UI. When the two disagree, what the app displays is the truth —
an appearance-setting check read `appearance_mode = dark` from `defaults` while the app was
showing, and had persisted, Light. Background: PR #264.

## Operating and asserting

All coordinates are in points, not pixels (a screenshot from a 2x device is twice the
coordinate values).

| Command | Effect |
|-|-|
| `idb ui swipe --udid $UDID x1 y1 x2 y2 --duration 0.5` | Draws one stroke on the canvas |
| `idb ui tap --udid $UDID x y` | Single tap — starts a dot stroke under `.anyInput`, so not usable for the UI toggle |
| `idb ui tap --udid $UDID x y --duration 0.15` | Tap that SwiftUI controls register (see below) |
| `idb ui tap --udid $UDID x y --duration 1.2` | Long press — opens context menus. A same-point `ui swipe` does NOT register as a long press |
| `idb ui key --udid $UDID <HID keycode>` (`--shift/--control/--option/--command`) | Hardware-keyboard event |
| `idb ui text --udid $UDID "..."` | Types text |
| `idb ui describe-all --udid $UDID` | Accessibility tree as JSON |
| `idb ui describe-point --udid $UDID x y` | The single accessibility element under one point |
| `xcrun simctl io $UDID screenshot out.png` | Screenshot (`idb screenshot` can fail with "No Image available to encode") |

`idb ui text` types through the simulator's active keyboard, so a device created on a
Japanese Mac inherits kana input and `"renamed"` arrives as `れなめd`. Switch the keyboard
and relaunch the app before typing into a field:

```sh
xcrun simctl spawn $UDID defaults write "Apple Global Domain" AppleKeyboards -array "en_US@sw=QWERTY;hw=Automatic"
```

Auto-capitalization still applies in a plain `TextField`, so the first character comes back
upper-cased. Assert on what `describe-all` reports for the field, not on the string that was
sent.
A zero-duration `ui tap` can miss a SwiftUI control without reporting anything: tapping
the Auto Save `Toggle` at the exact frame `describe-all` gave left its `AXValue` at 1,
while `--duration 0.15` at the same point flipped it. Read the control's `AXValue` back
instead of assuming the tap landed. The same applies to `ui swipe` on the canvas — a
swipe that lands outside the drawable area adds no stroke and reports success, so check
the stroke count before drawing conclusions from what did *not* happen afterwards.
Background: issue #290.
Wait 3–4 seconds between an action and the screenshot or `describe-all` that checks it.
A presentation started from a SwiftUI update pass is deferred a runloop turn and then
animates, so a screenshot taken immediately shows the *previous* state — which reads as
"the tap did nothing" and sends you diagnosing hit-testing that is not broken.

Out-of-process UI is invisible to `describe-all`: `UIActivityViewController`'s rows are
served by a remote view service and return nothing, so the share sheet is asserted from a
screenshot and driven by tapping computed coordinates (screenshot pixels ÷ device scale).

`describe-all` also stops at the sidebar. With the split view's sidebar open it returned eight
top-level elements — the application, the title, Toggle sidebar, a `Sidebar` group, More Actions,
New Note and the two empty-state labels — and none of the sidebar's rows. `describe-point` at a
row's coordinates does return it, carrying the row's whole label: the What's New row reads
`"What's New, New"` while its unread dot is up and `"What's New"` once it clears, which asserted
that marker in both directions without diffing screenshots. Use `describe-point` for anything
inside the sidebar's `List`. Background: issue #319, PR #323.

Assertions that need no screenshot diffing:

- **Strokes**: `describe-all` lists each PencilKit stroke as an element with
  `AXLabel: "Pen, black"` and a `frame` matching where it was drawn.
- **Persistence**: autosave writes the note into the app container —
  `ls "$(xcrun simctl get_app_container $UDID Individual.LikeAPaper data)/Documents/InboxFolder/"`
  shows a new timestamped `.plist` after drawing.

Verified example: two swipes (`100 300 300 500`, `300 500 150 650`), then `describe-all`
returned two "Pen, black" elements with matching frames and a new plist appeared in
InboxFolder.

## Seeding notes and tags without drawing

List, tag, and share flows need existing notes; they can be seeded from macOS without
drawing anything. A macOS `swift` script that mirrors the app's formats — `NoteEntity`
encoded with `PropertyListEncoder` into `Documents/InboxFolder/<timestamp>.pop`, and a
`[TagEntity]` JSON array into `Documents/Library/taglist.json` — written into the app
container (`xcrun simctl get_app_container $UDID Individual.LikeAPaper data`) appears in
the note list on the next launch, with tag strips rendered from the seeded `tagIds`.
Keep the seeded drawing an empty `PKDrawing()` (see docs/GOTCHAS.md on PencilKit
rendering off-device). Combined with the note-list stub below, this verified the tag
sheet, filter chips, and share sheet for PR #248 entirely from the command line.

Seed (and re-query the container path) only while no other session is using the
simulator: parallel sessions install their own builds over each other and the data
container can be replaced under you. Run verification on a dedicated simulator
(`xcrun simctl create`, or any device no other session uses), not the shared default.

Your own re-installs swap it too, with no other session involved: the path
`get_app_container` returns after `simctl install` differs from the one it returned
before, and the earlier seed belongs to the old container. Seed *after* the final
install and re-query the path every time — otherwise the app launches with an empty
note list, which reads as a load failure rather than a missing seed.

## Opening a note file via URL (onOpenURL path)

```sh
xcrun simctl openurl $UDID "file://$(xcrun simctl get_app_container $UDID Individual.LikeAPaper data)/Documents/InboxFolder/<note>.pop"
```

delivers the file URL to the app's `onOpenURL` handler — both while the app is running
(canvas swap) and from a cold launch — without automating the Files app. It cannot
exercise the security-scope path (files outside the app container); that still needs a
device and the real Files app. Background: PR #208.

Because the control panel is tappable at launch, this also reaches the canvas's own UI
for a *chosen* note: `openurl` a seeded note, then `idb ui tap` the Note Information
button to capture that note's info popover. The four states of issue #267 — no tags,
tags overflowing the row, a long file name, and the DEBUG ID row — were verified this
way, with no gesture injection.

## Limitations

- **No multi-touch**: idb's HID surface is single-touch (`multi-tap` is sequential taps at
  one point, not two fingers). The Simulator-only two-finger tap that hides the chrome
  (`CanvasView.toggleUIVisibility`) cannot be injected, so paper-only mode is unreachable
  from idb — but the chrome is visible at launch, so `idb ui tap` on Done reaches the note
  list without it (verified on iPad Pro 11-inch, iOS 26.5). Planned complement for the
  toggle itself: a Simulator-only keyboard shortcut driven by `idb ui key` (issue #196
  follow-up). Note the mode is narrower on device: it is only offered while the system
  "Only Draw with Apple Pencil" setting is on (issue #271, and the `.default` policy entry
  in [GOTCHAS.md](GOTCHAS.md)); the Simulator's two-finger tap bypasses that guard.
- **No canvas geometry**: `describe-all` lists the strokes but exposes no scroll view, so
  `PKCanvasView.contentSize` cannot be asserted. The infinite-scroll growth is covered by
  `PiecesOfPaperTests/PKCanvasViewWrapperTests.swift` instead. Background: issue #269.
- **Preferences cannot be changed while the canvas is open**: Setting sits behind the
  `fullScreenCover`, so a single window cannot toggle a preference mid-canvas. A user can
  with two iPad windows sharing the one `PreferenceStore` (`UIApplicationSupportsMultipleScenes`
  is on, which is why the store is owned by the App — PR #264), but idb cannot create the
  second scene.
- **idb cannot tap the tool picker's ⋯ popover**: `describe-all` lists its rows (Auto-Minimize,
  Draw with Finger, Pencil Settings…) as `CheckBox`/`Button` elements with plausible frames, but
  taps at those coordinates have no effect — tried several points inside the row and a longer
  `--duration`, with the menu staying open throughout. Tapping the ⋯ button itself works, so this
  is specific to the popover. To drive "Only Draw with Apple Pencil", write the preference behind
  it and relaunch the app:
  `xcrun simctl spawn $UDID defaults write com.apple.UIKit UIPencilOnlyDrawWithPencilKey -bool YES`
  (`YES` = pencil only, so the switch reads off). The key came from the runtime's UIKitCore
  strings; find others the same way:
  `strings "$(xcrun simctl runtime list -v | …)/RuntimeRoot/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore" | grep -i <name>`.
  Background: PR #281.
- **The first gesture after opening a menu is spent dismissing it**: a `ui swipe` delivered while
  the picker's ⋯ menu is open closes the menu and draws nothing, which reads as "drawing is
  broken" — the same swipe repeated draws normally. Check `describe-all` for the menu rows before
  operating, and assert state both before and after each injection.
- **The first gesture after `simctl launch` is dropped too**: a `ui swipe` sent right after launch
  leaves the canvas empty even though `describe-all` already lists the control panel and the
  picker; the next identical swipe draws. Two swipes issued in one shell command are both lost, so
  the retry has to be a separate injection. Seen while comparing pen state across two builds, where
  it first looked like the build under test had broken drawing. Background: PR #295.
- **Sidebar pages**: reachable on the shipping build in three taps, with no code change — tap Done
  to dismiss the auto-opened canvas, tap the sidebar toggle at the top-left of the detail pane (the
  sidebar starts collapsed, since `columnVisibility` defaults to `.detailOnly`), then tap the row.
  Verified on iPad Pro 11-inch, iOS 26.5, for What's New and Quick Tutorial. Land *directly* on a
  page only when those taps are in the way: change the
  initial `selection` in `RootSplitView` to that page (e.g. `.tutorial`) in a throwaway
  build. The `selection` change alone does not keep the canvas away — `sceneDidBecomeActive`
  still opens a blank note over the detail pane — but since the chrome is visible at launch,
  one `idb ui tap` on Done dismisses it and the chosen page is underneath (verified on
  iPhone 16 and iPad Pro 11-inch, iOS 26.5). On a build whose chrome is hidden at launch,
  Done is unreachable and the `noteStore.sceneDidBecomeActive()` call has to be stubbed out
  in the same throwaway build instead. Revert the change and rebuild before running the
  verification that goes into the PR.
- **Companion version**: the brew bottle is idb-companion 1.1.8 (built 2022). `ui swipe`
  verified against the iOS 18.3.1 and iOS 26.3 simulator runtimes.
- idb cannot inject touches into physical devices (iOS restriction); this workflow is
  Simulator-only. Canvas changes still require physical-iPad verification per CLAUDE.md.
- **`osascript` / System Events is not a fallback**: driving the Simulator window through
  AppleScript has no success path from a Claude Code session — without accessibility
  permission the AppleEvent simply times out, blocking for two minutes and returning
  nothing (hit while trying to read the Simulator's window coordinates). Inject touches
  with idb; when idb cannot do it (multi-touch, above), change the app or seed the state
  instead of automating the window.

## References

- [idb documentation](https://fbidb.io/docs/overview/) / [facebook/idb](https://github.com/facebook/idb)
- Python compatibility: [facebook/idb#896](https://github.com/facebook/idb/issues/896)
- App-side Simulator behavior: [CLAUDE.md](../CLAUDE.md) "Simulator testing",
  `PiecesOfPaper/View/Canvas/PKCanvasViewWrapper.swift`, `PiecesOfPaper/Model/FilePath.swift`
