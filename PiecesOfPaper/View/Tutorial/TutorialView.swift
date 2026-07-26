import SwiftUI

struct TutorialView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                basics
                Divider()
                dataManagement
                Divider()
                archive
                Divider()
                tag
                Divider()
                infiniteCanvas
                Divider()
                importantNotes
                Divider()
                faq
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private var basics: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Basics", systemImage: "pencil.tip.crop.circle")
            Bullet("Pieces of Paper is designed specifically for iPad and Apple Pencil")
            Bullet("The iOS app exists but offers limited practical value")
            Bullet("""
            When you launch the app, a blank white canvas fills the screen with the drawing tools \
            ready, so you can immediately start writing with your Apple Pencil
            """)
            Bullet("Double-tapping the Apple Pencil switches to eraser mode")
            Bullet("""
            Tapping the screen with your finger hides the controls for a plain sheet of paper, \
            and tapping again brings them back
            """)
            Bullet("""
            The Done button, in the floating panel in the top right, closes the window
            """)
            Bullet("The app features auto-save, which can be turned off in Setting > Auto Save")
        }
    }

    private var dataManagement: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Data Management", systemImage: "icloud")
            Bullet("""
            By default, this app uses your iCloud storage. \
            This enables data synchronization across devices
            """)
            Bullet("""
            You can also use local storage without iCloud. \
            Turn it off in Setting > Enable iCloud
            """)
            Bullet("""
            There is one major issue with iCloud integration. \
            You cannot download files created on other devices directly from Pieces of Paper. \
            Please note that you need to open the Files app to sync them
            """)
        }
    }

    private var archive: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Archive", systemImage: "archivebox")
            Bullet("The app includes an archive feature")
            Bullet("It's designed to work like Gmail's archive system (which you may not use, or may even dislike)")
            Bullet("""
            Archiving an item doesn't delete the actual file - \
            additional steps are required for permanent deletion
            """)
        }
    }

    private var tag: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Tag", systemImage: "tag")
            Bullet("The app includes a tag feature")
            Bullet("You can add/remove tags via Tag List")
            Bullet("Tag list files are stored in iCloud or local storage")
            Bullet("The path is Library/taglist.json")
            Bullet("""
            If synchronization issues occur during device migration or iCloud setting changes, \
            manually manage storage and select the appropriate file
            """)
        }
    }

    private var infiniteCanvas: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Infinite Canvas", systemImage: "scroll")
            Bullet("You can use infinite canvas by default")
            Bullet("Write something on the bottom-right corner of your note to expand the canvas")
            Bullet("Toggle this feature on/off in Setting > Infinite Scroll")
        }
    }

    private var importantNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Important Notes", systemImage: "exclamationmark.triangle")
            Bullet("""
            I have identified an issue where files created on iCloud may become inaccessible. \
            While the exact conditions are unknown, this can potentially cause the entire app to hang
            """)
            Bullet("""
            In the developer's environment, this occurred after creating more than 500 files. \
            However, I've confirmed that other files remain usable once the problematic files are removed
            """)
            Bullet("""
            If you encounter this issue, you can recover by creating a backup folder in your iCloud storage, \
            backing up all files from Pieces of Paper's Inbox, \
            and then attempting to delete everything in Inbox
            """)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }

    private var faq: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "FAQ", systemImage: "questionmark.circle")
            FAQItem(
                question: "Is this app free?",
                answer: """
                Yes, it's **free**. In fact, all the source code is \
                [publicly available](https://github.com/0si43/PiecesOfPaper).
                """
            )
            FAQItem(
                question: "Where should I report bugs?",
                answer: """
                Please create an issue on [GitHub Repository](https://github.com/0si43/PiecesOfPaper). \
                However, I cannot promise to fix every issue (as this is a free app!). \
                If you're a developer, I'd be delighted to receive your pull requests!😁
                """
            )
            FAQItem(
                question: """
                This app's bug ruined my notes! I worked hard on those notes and now they're gone! \
                This is terrible!
                """,
                answer: """
                Sorry for your inconvenience. Please note that Pieces of Paper is developed by \
                an individual developer and offered as a free app.

                While I'm confident in the app's usability, I cannot guarantee 100% stability. \
                For important documents, I cannot take responsibility for any data loss. \
                I recommend regularly exporting your work as image files or using a more reliable app \
                for critical documents.
                """
            )
        }
    }
}

private struct SectionHeader: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.title2.bold())
    }
}

private struct Bullet: View {
    private let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct FAQItem: View {
    let question: LocalizedStringKey
    let answer: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Text(answer)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    TutorialView()
}
