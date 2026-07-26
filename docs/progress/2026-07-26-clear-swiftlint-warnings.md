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
