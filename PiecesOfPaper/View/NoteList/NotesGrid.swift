//
//  NotesGrid.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/10/31.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI
import PencilKit

struct NotesGrid: View {
    @State var isShowActivityView = false
    @State var documentToShare: NoteDocument?
    @EnvironmentObject var noteViewModel: NotesViewModel

    let gridItem = GridItem(.adaptive(minimum: 250), spacing: 50.0)
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

    var body: some View {
        LazyVGrid(columns: [gridItem]) {
            ForEach((0..<noteViewModel.publishedNoteDocuments.count), id: \.self) { index in
                VStack {
                    NoteImage(noteDocument: $noteViewModel.publishedNoteDocuments[index])
                    .contextMenu {
                        Button(action: {
                            duplicate(noteDocument: noteViewModel.publishedNoteDocuments[index])
                        }) {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        if noteViewModel.publishedNoteDocuments[index].isArchived {
                                Button(action: {
                                    unarchive(noteDocument: noteViewModel.publishedNoteDocuments[index])
                                }) {
                                    Label("Unarchive", systemImage: "arrow.up.square")
                                }
                                if #available(iOS 15.0, *) {
                                    Button(role: .destructive) {
                                        delete(noteDocument: noteViewModel.publishedNoteDocuments[index])
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        } else {
                            Button(action: {
                                archive(noteDocument: noteViewModel.publishedNoteDocuments[index])
                            }) {
                                Label("Archive", systemImage: "arrow.down.square")
                            }
                        }
                        Button(action: {
                            share(noteDocument: noteViewModel.publishedNoteDocuments[index])
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button(action: {
                            TagListRouter.shared.showTagList(noteDocument: noteViewModel.publishedNoteDocuments[index])
                        }) {
                            Label("Tag", systemImage: "tag")
                        }
                    }
                    TagHStack(tags: noteViewModel.getTagToNote(document: noteViewModel.publishedNoteDocuments[index]))
                        .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $isShowActivityView) {
            activityViewController
        }
    }

    func duplicate(noteDocument: NoteDocument) {
        guard let savingUrl = FilePath.savingUrl else { return }
        let newUrl = savingUrl.appendingPathComponent(FilePath.fileName)
        try? FileManager.default.copyItem(at: noteDocument.fileURL, to: newUrl)
    }

    func archive(noteDocument: NoteDocument) {
        noteViewModel.archive(document: noteDocument)
    }

    func unarchive(noteDocument: NoteDocument) {
        noteViewModel.unarchive(document: noteDocument)
    }

    func delete(noteDocument: NoteDocument) {
        try? FileManager.default.removeItem(at: noteDocument.fileURL)
    }

    func share(noteDocument: NoteDocument) {
        documentToShare = noteDocument
        isShowActivityView = true
    }
}

// struct NotesGrid_Previews: PreviewProvider {
//    static var previews: some View {
//        NotesGrid()
//    }
// }
