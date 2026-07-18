# CLAUDE.md

## Language

- All GitHub-facing text is written in English: PR titles/bodies, issue titles/bodies, commit messages, and code comments.
- Conversation with the user may be in Japanese; the repository's written artifacts stay in English.

## Verification

- Changes that touch the canvas or PencilKit rendering (PKCanvasView, PKDrawing, thumbnails) must be verified on a physical iPad with an Apple Pencil before merge. PencilKit keeps process-wide renderer state that the Simulator and unit tests cannot exercise — rendering `PKDrawing.image` off the main thread breaks stroke drawing app-wide on device only (#187).
