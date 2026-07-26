import SwiftUI

struct SectionHeader: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.title2.bold())
    }
}
