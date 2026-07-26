- [x] Document data-container re-seeding and per-note popover capture in SIMULATOR_E2E (issue #287, PR #296)
  - `simctl install` swaps the data container even with no parallel session, so the seed
    has to come after the final install with the path re-queried
  - `openurl` + a tap on the launch-visible control panel captures a chosen note's info
    popover; used for the four states in issue #267
