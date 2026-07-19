# Progress fragments

Holding area for entries that have not yet been consolidated into the Work Log of
[docs/PROGRESS.md](../PROGRESS.md). Each PR adds one new file here instead of
appending to PROGRESS.md directly, so parallel PRs never conflict on the same file.

## Writing a fragment

- File name: `YYYY-MM-DD-<slug>.md` — the date is the work date, the slug is a short identifier such as the branch name.
- Body: bullet list only, same format as the Work Log. No headings (`#`).

```markdown
- [x] Add some feature (issue #N, PR #M)
  - Notes on key decisions, if any
```

## Consolidation

`swift scripts/consolidate-progress.swift` merges fragments into the
`### YYYY-MM-DD` sections of the PROGRESS.md Work Log (newest date first,
appending to an existing section for the same date) and deletes the files it
consumed. Run it only when the user asks, one run at a time, and put the result
in a chore PR.
