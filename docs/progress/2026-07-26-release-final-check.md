- [x] Explain once why tapping no longer hides the canvas controls (issue #302, PR #305)
  - `CanvasView` shows a one-time alert on iPad while `UIPencilInteraction.prefersPencilOnlyDrawing`
    is false, so people updating from 3.3.0 — which forced `.pencilOnly` and always had the tap —
    learn that finger drawing and the tap-to-hide gesture are exclusive
  - The app cannot change the setting itself: `prefersPencilOnlyDrawing` is a read-only class
    property, so the alert points at the tool picker's menu and Settings > Apple Pencil
