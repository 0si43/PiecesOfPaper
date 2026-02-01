//
//  NoteInformation.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/12.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct NoteInformationView: View {
    private(set) var document: NoteDocument
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
                Text("🛠" + document.entity.id.uuidString)
                    .minimumScaleFactor(0.5)
                Divider()
                #endif
            }
            Group {
                Text(document.fileURL.lastPathComponent)
                    .minimumScaleFactor(0.5)
                Divider()
                Text(dataFormatter.string(from: document.entity.createdDate))
                Divider()
                Text(dataFormatter.string(from: document.entity.updatedDate))
                Divider()
                Text(document.isArchived ? "Archived" : "Inbox")
                Divider()
                if document.entity.tags.isEmpty {
                    Text("No tag")
                } else {
                    ScrollView(.horizontal) {
                        TagHStack(tags: document.entity.tags)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    NoteInformationView(document: NoteDocument.createTestData())
}
