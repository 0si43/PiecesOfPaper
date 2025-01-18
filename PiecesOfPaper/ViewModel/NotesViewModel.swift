//
//  NotesViewModel.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/11/03.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import PencilKit

final class NotesViewModel: ObservableObject {
    var objectWillChange = ObjectWillChangePublisher()
    var publishedNoteDocuments = [NoteDocument]()
    private var noteDocuments = [NoteDocument]()
    private var counter = 0

    var isLoaded = false
    var showArchiveAlert = false

    var isListConditionSheet = false {
        willSet {
            objectWillChange.send()
        }
    }

    var documentToShare: NoteDocument?
    var showActivityView = false {
        willSet {
            objectWillChange.send()
        }
    }

    var activityViewController: UIActivityViewControllerWrapper? {
        guard let document = documentToShare else { return nil }
        let drawing = document.entity.drawing
        var image = UIImage()
        let trait = UITraitCollection(userInterfaceStyle: .light)
        trait.performAsCurrent {
            image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
        }

        return UIActivityViewControllerWrapper(activityItems: [image])
    }

    var didFirstFetchRequest = false
    enum TargetDirectory: String {
        case inbox, archived, all
    }

    private var directory: TargetDirectory
    var isTargetDirectoryInbox: Bool {
        directory == .inbox
    }

    var isTargetDirectoryArchived: Bool {
        directory == .archived
    }

    var listCondition: ListCondition {
        didSet {
            saveConditionInDevice()
            publish()
        }
    }

    private var documentsAppliedConditions: [NoteDocument] {
        var notes = noteDocuments
        listCondition.filterBy.forEach { filteringTag in
            notes = notes.filter { $0.entity.tags.contains(filteringTag) }
        }
        switch listCondition.sortOrder {
        case .ascending:
            switch listCondition.sortBy {
            case .updatedDate:
                notes = notes.sorted { $0.entity.updatedDate < $1.entity.updatedDate }
            case .createdDate:
                notes = notes.sorted { $0.entity.createdDate < $1.entity.createdDate }
            }
        case .descending:
            switch listCondition.sortBy {
            case .updatedDate:
                notes = notes.sorted { $0.entity.updatedDate > $1.entity.updatedDate }
            case .createdDate:
                notes = notes.sorted { $0.entity.createdDate > $1.entity.createdDate }
            }
        }
        return notes
    }

    init(targetDirectory: TargetDirectory) {
        self.directory = targetDirectory
        let decoder = JSONDecoder()
        guard let data = UserDefaults.standard.data(forKey: "listCondition(" + directory.rawValue + ")"),
              let condition = try? decoder.decode(ListCondition.self, from: data) else {
                  self.listCondition = ListCondition()
                  saveConditionInDevice()
                  return
              }
        self.listCondition = condition
    }

    private func saveConditionInDevice() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(listCondition) else { return }
        UserDefaults.standard.set(data, forKey: "listCondition(" + directory.rawValue + ")")
    }

    func fetch() {
        openDocuments()
    }

    private func openDocuments() {
        let urls = getFileUrl()
        guard !urls.isEmpty else {
            noteDocuments.removeAll()
            isLoaded = true
            objectWillChange.send()
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.counter = urls.count
        }
        urls.forEach { url in
            open(fileUrl: url)
        }
    }

    private func getFileUrl() -> [URL] {
        guard let inboxUrl = FilePath.inboxUrl,
              var inboxFileNames = try? FileManager.default.contentsOfDirectory(atPath: inboxUrl.path),
              let archivedUrl = FilePath.archivedUrl,
              var archivedFileNames =
                try? FileManager.default.contentsOfDirectory(atPath: archivedUrl.path) else { return [] }

        inboxFileNames = inboxFileNames.filter { $0.hasSuffix(".plist") }
        archivedFileNames = archivedFileNames.filter { $0.hasSuffix(".plist") }

        switch directory {
        case .inbox:
            return inboxFileNames.map { inboxUrl.appendingPathComponent($0) }
        case .archived:
            return archivedFileNames.map { archivedUrl.appendingPathComponent($0) }
        case .all:
            let inboxUrls = inboxFileNames.map { inboxUrl.appendingPathComponent($0) }
            let archivedUrls = archivedFileNames.map { archivedUrl.appendingPathComponent($0) }
            return inboxUrls + archivedUrls
        }
    }

    private func open(fileUrl: URL) {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else { return }
        let document = NoteDocument(fileURL: fileUrl)

        document.open { [weak self] success in
            if success {
                defer {
                    document.close()
                }

                self?.noteDocuments.append(document)
                self?.publishIfLoadEnded()
            } else {
                fatalError("could not open document")
            }
        }
    }

    private func publishIfLoadEnded() {
        if counter <= noteDocuments.count {
            publish()
        }
    }

    private func publish() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.publishedNoteDocuments = self.documentsAppliedConditions
            self.isLoaded = true
            self.counter = 0
            self.objectWillChange.send()
        }
    }

    func update() {
        isLoaded = false
        noteDocuments.removeAll()
        objectWillChange.send()
        openDocuments()
    }

    func duplicate(_ document: NoteDocument) {
        guard let inboxUrl = FilePath.inboxUrl,
              let archivedUrl = FilePath.archivedUrl else { return }

        let directory = isTargetDirectoryArchived ? archivedUrl : inboxUrl
        let newUrl = directory.appendingPathComponent(FilePath.fileName)
        let entity = NoteEntity(drawing: document.entity.drawing)
        let newDocument = NoteDocument(fileURL: newUrl, entity: entity)
        newDocument.save(to: newUrl, for: .forCreating) { [weak self] success in
            if success {
                self?.noteDocuments.append(newDocument)
                self?.publish()
            }
        }
    }

    func delete(_ document: NoteDocument) {
        try? FileManager.default.removeItem(at: document.fileURL)
        noteDocuments = Array(noteDocuments.filter { $0.entity.id != document.entity.id })

        publish()
    }

    func share(_ document: NoteDocument) {
        documentToShare = document
        showActivityView = true
    }

    func archive(_ document: NoteDocument) {
        guard let archivedUrl = FilePath.archivedUrl else { return }
        let toUrl = archivedUrl.appendingPathComponent(document.fileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: document.fileURL, to: toUrl)
        } catch {
            print("Could not archive: ", error.localizedDescription)
        }

        noteDocuments = Array(noteDocuments.filter { $0.entity.id != document.entity.id })
        publish()
    }

    func unarchive(_ document: NoteDocument) {
        guard let inboxUrl = FilePath.inboxUrl else { return }
        let toUrl = inboxUrl.appendingPathComponent(document.fileURL.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: document.fileURL, to: toUrl)
        } catch {
            print("Could not unarchive: ", error.localizedDescription)
        }

        noteDocuments = Array(noteDocuments.filter { $0.entity.id != document.entity.id })
        publish()
    }

    func getTagToNote(document: NoteDocument) -> [TagEntity] {
        let tagModel = TagModel()
        let tags = tagModel.tags
        return tags.filter {
            document.entity.tags.contains($0)
        }
    }

    func toggleIsListConditionPopover() {
        isListConditionSheet.toggle()
        objectWillChange.send()
    }

    func showArchiveOrUnarchiveAlert() {
        showArchiveAlert = true
        objectWillChange.send()
    }

    func allArchive() {
        noteDocuments.forEach { archive($0) }
        publish()
    }

    func allUnarchive() {
        noteDocuments.forEach { unarchive($0) }
        publish()
    }
}
