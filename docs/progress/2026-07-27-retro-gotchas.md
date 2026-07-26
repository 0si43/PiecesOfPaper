- [x] Record the pitfalls found during the release check (issue #325, PR #327)
  - `docs/GOTCHAS.md`: `#available` is a runtime check and does not conjure the API — the iOS 26
    close button compiled locally on Xcode 26.6 and failed CI, whose `macos-15` image defaults to
    Xcode 16.4 (issue #320); an `.alert` message drops `Image` interpolation; a multi-line string
    literal keeps the indentation its closing delimiter does not cover (issue #309)
  - `docs/SIMULATOR_E2E.md`: a simulator's preference domain survives `simctl uninstall`, so a
    later `defaults write` brings back every key cfprefsd was holding and a "fresh install" check
    starts with flags the app should never see
  - `CLAUDE.md`: a Scope section on where the maintainer draws the line between a wording defect
    and code for a rare state
