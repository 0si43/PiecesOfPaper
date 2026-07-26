import SwiftUI

struct TutorialView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                basics
                Divider()
                dataManagement
                Divider()
                trash
                Divider()
                tag
                Divider()
                infiniteCanvas
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
            Bullet("""
            You can also draw with your finger: turn off Only Draw with Apple Pencil, either from \
            the drawing tools' menu or in the iOS Settings app under Apple Pencil
            """)
            Bullet("""
            While Only Draw with Apple Pencil is on, tapping the screen with your finger hides the \
            controls for a plain sheet of paper, and tapping again brings them back
            """)
            Bullet("""
            The Done button, in the floating panel in the top right, closes the window
            """)
            Bullet("The app saves automatically, which you can turn off in Settings > Auto Save")
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
            Turn it off in Settings > Enable iCloud
            """)
        }
    }

    private var trash: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Trash", systemImage: "trash")
            Bullet("Notes you no longer want in the Inbox go to Trash")
            Bullet("""
            It's designed to work like Gmail's archive (which you may not use, or may even dislike): \
            moving a note to Trash takes it out of the Inbox but keeps it
            """)
            Bullet("""
            Moving a note to Trash doesn't delete the actual file — \
            additional steps are required for permanent deletion
            """)
        }
    }

    private var tag: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Tag", systemImage: "tag")
            Bullet("The app includes a tag feature")
            Bullet("You can add/edit/remove tags via Tag List")
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
            Bullet("The infinite canvas is on by default")
            Bullet("Write something in the bottom-right corner of your note to expand the canvas")
            Bullet("Toggle this feature on or off in Settings > Infinite Scroll")
        }
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
                Please open an issue in the [GitHub repository](https://github.com/0si43/PiecesOfPaper). \
                However, I cannot promise to fix every issue (this is a free app!). \
                If you're a developer, I'd be delighted to receive your pull requests!😁
                """
            )
            FAQItem(
                question: """
                A bug in this app ruined my notes! I worked hard on those notes and now they're gone! \
                This is terrible!
                """,
                answer: """
                Sorry for the inconvenience. Please note that Pieces of Paper is developed by \
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
