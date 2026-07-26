- [x] Rebuild NoteInformationView on Grid so its two columns stay aligned (issue #267, PR #276)
  - The hand-built `HStack` of two `VStack`s let the Tags row (`TagHStack` at `minHeight: 60`)
    grow the right column only, drifting every separator below it
  - Separators are now `Divider()`s directly in the `Grid`, spanning all columns, so the
    `#if DEBUG` ID row no longer has to keep per-column `Divider()` counts in sync by hand
  - Vertical column divider dropped; the label column is `.foregroundStyle(.secondary)` instead
  - Popover sizing (`CanvasView`) deliberately untouched — its width still tracks the tag count
