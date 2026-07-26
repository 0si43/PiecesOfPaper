- [x] Add a Signing / distribution section to GOTCHAS (issue #330, PR #331)
  - Xcode Cloud build 89 (4.0.0 / build 30) archived fine and then failed all three export methods with
    `Automatic signing cannot register bundle identifier "Individual.LikeAPaper.ThumbnailExtension"` —
    the two QuickLook extensions had no App ID on the Developer Portal, which listed only the wildcard
    `*` and the app's own `Individual.LikeAPaper`. Registering both by hand and rebuilding fixed it
  - Certificates were valid the whole time (`Apple Development: Created via API`, to 2027-02-04); the
    App Store Connect page files the failure under "Code Signing" and shows nothing but a generic
    message and exit code 70, which points at the wrong cause
  - The gap survived because neither extension sets `CODE_SIGN_ENTITLEMENTS`: a bundle requesting no
    entitlements is coverable by the wildcard App ID during development, while App Store distribution
    requires an explicit one per bundle. 3.3.0 (2026-02-03) predates the extensions (2026-07-19), so no
    distribution in between could have surfaced it
  - The archive log also gave issue #313 one half of its unmeasured comparison, recorded there as a
    comment: with the `membershipExceptions` entry in place, `PiecesOfPaper.entitlements` is consumed
    only by `ProcessProductPackaging` and never copied into the bundle by `CpResource`
