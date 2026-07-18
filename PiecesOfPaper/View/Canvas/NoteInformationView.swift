//
//  NoteInformation.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/12.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteInformationView: View {
    private(set) var note: NoteData
    let dataFormatter: DateFormatter = {
        let dataFormatter = DateFormatter()
        dataFormatter.dateStyle = .medium
        dataFormatter.timeStyle = .medium
        return dataFormatter
    }()

    var body: some View {
        HStack {
            leftColumnView
            Divider()
            rightColumnView
        }
    }

    private var leftColumnView: some View {
        VStack {
            Group {
                #if DEBUG
                Text("🛠" + "ID")
                Divider()
                #endif
            }
            Group {
                Text("File Name")
                Divider()
                Text("Created Date")
                Divider()
                Text("Updated Date")
                Divider()
                Text("Archive Status")
                Divider()
                Text("Tags")
            }
        }
        .scaledToFit()
    }

    private var rightColumnView: some View {
        VStack {
            Group {
                #if DEBUG
                Text("🛠" + note.entity.id.uuidString)
                    .minimumScaleFactor(0.5)
                Divider()
                #endif
            }
            Group {
                Text(note.fileURL.lastPathComponent)
                    .minimumScaleFactor(0.5)
                Divider()
                Text(dataFormatter.string(from: note.entity.createdDate))
                Divider()
                Text(dataFormatter.string(from: note.entity.updatedDate))
                Divider()
                Text(note.isArchived ? "Archived" : "Inbox")
                Divider()
                if note.entity.tags.isEmpty {
                    Text("No tag")
                } else {
                    ScrollView(.horizontal) {
                        TagHStack(tags: note.entity.tags)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    NoteInformationView(note: NoteData.createTestData())
}
