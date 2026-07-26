import UIKit
import LinkPresentation

/// Supplies the shared drawing together with a name for the share sheet header.
/// A bare UIImage carries no metadata, so iOS falls back to naming the type and the
/// header reads "PNG image" for every note (issue #270).
final class NoteShareItemSource: NSObject, UIActivityItemSource {
    private let image: UIImage
    private let title: String

    init(image: UIImage, updatedDate: Date, locale: Locale = .current) {
        self.image = image
        self.title = Self.title(updatedDate: updatedDate, locale: locale)
        super.init()
    }

    // Notes have no title, so the update date is what distinguishes them — the same
    // naming the grid uses under VoiceOver (NoteThumbnailView.accessibilityLabel)
    static func title(updatedDate: Date, locale: Locale = .current) -> String {
        let date = updatedDate.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale)
        )
        return "Note, \(date)"
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        image
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        title
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }
}
