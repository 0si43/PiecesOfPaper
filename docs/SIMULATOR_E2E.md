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
[CLAUDE.md](../CLAUDE.md)); drawing works immediately because Simulator builds use
`drawingPolicy = .anyInput`. The canvas chrome is visible from launch — a floating
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
| `idb ui tap --udid $UDID x y --duration 1.2` | Long press — opens context menus. A same-point `ui swipe` does NOT register as a long press |
| `idb ui key --udid $UDID <HID keycode>` (`--shift/--control/--option/--command`) | Hardware-keyboard event |
| `idb ui text --udid $UDID "..."` | Types text |
| `idb ui describe-all --udid $UDID` | Accessibility tree as JSON |
| `xcrun simctl io $UDID screenshot out.png` | Screenshot (`idb screenshot` can fail with "No Image available to encode") |

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

## Opening a note file via URL (onOpenURL path)

```sh
xcrun simctl openurl $UDID "file://$(xcrun simctl get_app_container $UDID Individual.LikeAPaper data)/Documents/InboxFolder/<note>.pop"
```

delivers the file URL to the app's `onOpenURL` handler — both while the app is running
(canvas swap) and from a cold launch — without automating the Files app. It cannot
exercise the security-scope path (files outside the app container); that still needs a
device and the real Files app. Background: PR #208.

## Limitations

- **No multi-touch**: idb's HID surface is single-touch (`multi-tap` is sequential taps at
  one point, not two fingers). The Simulator-only two-finger tap that hides the chrome
  (`CanvasView.toggleUIVisibility`) cannot be injected, so paper-only mode is unreachable
  from idb — but the chrome is visible at launch, so `idb ui tap` on Done reaches the note
  list without it (verified on iPad Pro 11-inch, iOS 26.5). Planned complement for the
  toggle itself: a Simulator-only keyboard shortcut driven by `idb ui key` (issue #196
  follow-up).
- **Sidebar pages**: to land directly on Quick Tutorial, Setting or Tag List, change the
  initial `selection` in `RootSplitView` to that page (e.g. `.tutorial`) in a throwaway
  build — the detail pane shows the page at launch, no blank note opens, and idb swipes
  scroll it directly (used for the PR #247 screenshots). Revert the change and rebuild
  before running the verification that goes into the PR.
- **Companion version**: the brew bottle is idb-companion 1.1.8 (built 2022). `ui swipe`
  verified against the iOS 18.3.1 and iOS 26.3 simulator runtimes.
- idb cannot inject touches into physical devices (iOS restriction); this workflow is
  Simulator-only. Canvas changes still require physical-iPad verification per CLAUDE.md.

## References

- [idb documentation](https://fbidb.io/docs/overview/) / [facebook/idb](https://github.com/facebook/idb)
- Python compatibility: [facebook/idb#896](https://github.com/facebook/idb/issues/896)
- App-side Simulator behavior: [CLAUDE.md](../CLAUDE.md) "Simulator testing",
  `PiecesOfPaper/View/Canvas/PKCanvasViewWrapper.swift`, `PiecesOfPaper/Model/FilePath.swift`
