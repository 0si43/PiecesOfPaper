import SwiftUI
import PencilKit

@main
struct PiecesOfPaperApp: App {
    // Owned here rather than by RootSplitView: UIApplicationSupportsMultipleScenes
    // is on, and a per-scene @State would let two windows disagree about the
    // preferences until relaunch
    @State private var preferenceStore = PreferenceStore()

    var body: some Scene {
        WindowGroup {
            RootSplitView()
                .environment(preferenceStore)
        }
    }
}
