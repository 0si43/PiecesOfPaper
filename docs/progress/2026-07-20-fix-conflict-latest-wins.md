- [x] Fix NoteDocument conflict resolution to actually keep the newest version (issue #200)
  - `resolveConflictIfNeeded()` claimed "later wins" but unconditionally kept the local
    current version; it now promotes the newest of current + unresolved conflict versions
    via `NSFileVersion.replaceItem(at:)` before removing the others.
  - The pick-newest decision is factored into `NoteConflictResolver.newestVersionIndex`
    (plain `Date?` values) because conflict versions cannot be fabricated in iOS unit
    tests; ties favor the current version so no needless file replacement happens.
  - End-to-end conflict verification still requires two physical devices producing a
    real iCloud conflict.
