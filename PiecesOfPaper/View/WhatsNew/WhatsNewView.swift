import SwiftUI

struct WhatsNewView: View {
    @Environment(PreferenceStore.self) private var preferenceStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ForEach(Array(ReleaseNote.all.enumerated()), id: \.element.id) { index, note in
                    if index > 0 {
                        Divider()
                    }
                    release(note)
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding()
        }
        // Reaching this body is the whole gate: `RootSplitView.selection` is plain
        // @State with no restoration, so the page cannot be showing without the user
        // having picked it. Persisting the selection would break that assumption
        .onAppear {
            guard let latest = ReleaseNote.latest else { return }
            preferenceStore.markWhatsNewSeen(version: latest.version)
        }
    }

    private func release(_ note: ReleaseNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Version \(note.version)", systemImage: "sparkles")
            Text(note.date.formatted(date: .long, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(Array(note.highlights.enumerated()), id: \.offset) { _, highlight in
                Bullet(highlight)
            }
        }
    }
}

#Preview {
    WhatsNewView()
        .environment(PreferenceStore())
}
