- [x] Document the partial-equality SwiftUI trap and two idb facts (issue #293, PR #294)
  - `docs/GOTCHAS.md`: a value type whose `==` compares only part of its fields makes SwiftUI
    skip the re-render — the `TagEntity` id-only `==` behind PR #279, with the four call sites
    that now compare `.id` explicitly
  - `docs/SIMULATOR_E2E.md`: `idb ui text` goes through the simulator's active keyboard, so a
    device created on a Japanese Mac turns `"renamed"` into `れなめd`; and the "Sidebar pages"
    bullet was wrong that no blank note opens — it does, on both iPhone and iPad, and tapping
    Done is what reveals the chosen page
