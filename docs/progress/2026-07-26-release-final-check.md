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
