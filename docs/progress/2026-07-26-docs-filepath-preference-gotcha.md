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
