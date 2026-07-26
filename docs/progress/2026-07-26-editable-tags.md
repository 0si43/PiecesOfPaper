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
