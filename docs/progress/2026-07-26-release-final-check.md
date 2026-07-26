- [x] Explain once why tapping no longer hides the canvas controls (issue #302, PR #305)
  - `CanvasView` shows a one-time alert on iPad while `UIPencilInteraction.prefersPencilOnlyDrawing`
    is false, so people updating from 3.3.0 — which forced `.pencilOnly` and always had the tap —
    learn that finger drawing and the tap-to-hide gesture are exclusive
  - The app cannot change the setting itself: `prefersPencilOnlyDrawing` is a read-only class
    property, so the alert points at the tool picker's menu and Settings > Apple Pencil
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
