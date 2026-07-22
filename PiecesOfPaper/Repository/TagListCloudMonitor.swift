import Foundation

/// Watches the iCloud metadata index for taglist.json so the tag list can
/// reload once an undownloaded copy materializes (fetchAll returns an empty
/// list until then) or a change synced from another device arrives.
@MainActor
final class TagListCloudMonitor {
    private let query = NSMetadataQuery()
    private var observers: [NSObjectProtocol] = []
    var onUpdate: (@MainActor () -> Void)?

    init() {
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K == %@",
                                      NSMetadataItemFSNameKey,
                                      "taglist.json")
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .NSMetadataQueryDidFinishGathering,
                                            object: query,
                                            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.onUpdate?() }
        })
        observers.append(center.addObserver(forName: .NSMetadataQueryDidUpdate,
                                            object: query,
                                            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.onUpdate?() }
        })
        query.start()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
