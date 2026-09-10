- [x] Create the note directories when they are missing (issue #332, PR #333)
  - Root cause: `FilePath.makeDirectoryIfNeeded()` only ran from the `enablediCloud` didSet and the
    ubiquity location-changed closure, and iCloud defaults to on, so a user who never touched that
    switch never created `Archived`. `NoteRepository.save()` creates its own parent, which is why
    `InboxFolder` existed and every move to Trash failed on the missing one.
  - Regression window: until 3.2.0 the root view called `DrawingsPlistConverter.convert()`
    unconditionally from `onAppear` and `makeDirectoryIfNeeded()` was its first statement, so every
    launch created both folders. "remove AppViewModel" (e5fd68d / f0b58a3, shipped in 3.2.0) put
    that call behind `if DrawingsPlistConverter.hasDrawingsPlist`, which is false without a legacy
    plist and false forever after a conversion renames the file. 5bda23b (3.3.0) only deleted code
    that had already been dead for this purpose for a year.
  - `move(fileUrl:toDirectoryAt:)` and a new `duplicate(_:inDirectoryAt:)` overload now share the
    `createDirectoryIfNeeded(at:)` helper extracted from `save()`; `RootSplitView.onAppear` calls
    `makeDirectoryIfNeeded()` unconditionally so a fresh container has both folders.
  - Verified against `origin/main` in the Simulator: the baseline reproduces the
    `Failed to move the note.` alert and creates no `Archived` at launch.
