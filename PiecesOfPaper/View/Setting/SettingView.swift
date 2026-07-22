import SwiftUI

struct SettingView: View {
    @Environment(PreferenceStore.self) private var preferenceStore
    private let repositoryUrl = URL(string: "https://github.com/0si43/PiecesOfPaper")
    private let developerSiteUrl = URL(string: "https://www.shetommy.com/")

    var body: some View {
        @Bindable var preferenceStore = preferenceStore
        List {
            Section(header: Text("Preference")) {
                Toggle(isOn: $preferenceStore.enablediCloud) {
                    Label("Enable iCloud", systemImage: "icloud")
                }
                Toggle(isOn: $preferenceStore.enabledAutoSave) {
                    Label("Auto Save", systemImage: "gearshape")
                }
                Toggle(isOn: $preferenceStore.enabledInfiniteScroll) {
                    Label("Infinite Scroll", systemImage: "scroll")
                }
            }
            Section(header: Text("About")) {
                if let url = repositoryUrl {
                    Link(destination: url) {
                        Label("Github Repository", systemImage: "ellipsis.curlybraces")
                    }
                }

                if let url = developerSiteUrl {
                    Link(destination: url) {
                        Label("Developer Site", systemImage: "wrench")
                    }
                }
            }
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    SettingView()
        .environment(PreferenceStore())
}
