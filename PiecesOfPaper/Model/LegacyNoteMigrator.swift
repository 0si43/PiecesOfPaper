import Foundation

/// Renames legacy `.plist` notes to the current note file extension.
///
/// Runs on every enumeration instead of behind a one-time flag: devices on
/// older app versions keep syncing `.plist` files into the iCloud container,
/// and undownloaded iCloud placeholders cannot be renamed until they are
/// materialized. Each call is idempotent and normally a zero-work scan.
enum LegacyNoteMigrator {
    static func migrate(in directoryUrl: URL, fileManager: FileManager = .default) {
        guard let fileNames = try? fileManager.contentsOfDirectory(atPath: directoryUrl.path) else { return }
        let legacySuffix = "." + FilePath.legacyNoteFileExtension
        for fileName in fileNames {
            if fileName.hasSuffix(legacySuffix), !fileName.hasPrefix(".") {
                let source = directoryUrl.appendingPathComponent(fileName)
                let destination = source.deletingPathExtension()
                    .appendingPathExtension(FilePath.noteFileExtension)
                guard !fileManager.fileExists(atPath: destination.path) else { continue }
                // Uncoordinated moveItem matches NoteRepository.move; failures
                // are skipped and retried on the next enumeration.
                try? fileManager.moveItem(at: source, to: destination)
            } else if fileName.hasPrefix("."), fileName.hasSuffix(legacySuffix + ".icloud") {
                // Undownloaded placeholder ".<name>.plist.icloud": request the
                // download so a later pass can rename the materialized file.
                let realName = String(fileName.dropFirst().dropLast(".icloud".count))
                try? fileManager.startDownloadingUbiquitousItem(
                    at: directoryUrl.appendingPathComponent(realName)
                )
            }
        }
    }
}
