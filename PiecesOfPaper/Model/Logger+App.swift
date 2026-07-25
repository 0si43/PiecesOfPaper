import os

extension Logger {
    // Hardcoded rather than Bundle.main.bundleIdentifier: this file is compiled
    // into the app target only, and a constant keeps the Console filter greppable
    private static let subsystem = "Individual.LikeAPaper"

    static let tagRepository = Logger(subsystem: subsystem, category: "TagRepository")
    static let noteMetadataCache = Logger(subsystem: subsystem, category: "NoteMetadataCache")
    static let noteDocument = Logger(subsystem: subsystem, category: "NoteDocument")
    static let noteRepository = Logger(subsystem: subsystem, category: "NoteRepository")
    static let noteStore = Logger(subsystem: subsystem, category: "NoteStore")
    static let filePath = Logger(subsystem: subsystem, category: "FilePath")
    static let legacyNoteMigrator = Logger(subsystem: subsystem, category: "LegacyNoteMigrator")
}
