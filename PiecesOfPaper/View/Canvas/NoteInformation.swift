//
//  NoteInformation.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/12.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import PencilKit
import SwiftUI

struct NoteInformation: View {
    var document: NoteDocument?
    let dataFormatter: DateFormatter = {
        let dataFormatter = DateFormatter()
        dataFormatter.dateStyle = .medium
        dataFormatter.timeStyle = .medium
        return dataFormatter
    }()

    var body: some View {
        if let document = document {
            HStack {
                VStack {
                    Group {
                        #if DEBUG
                        HStack {
                            Text("🛠")
                            Text("ID")
                        }
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
                Divider()
                VStack {
                    Group {
                        #if DEBUG
                            ScrollView(.horizontal) {
                                HStack {
                                    Text("🛠")
                                    Text(document.entity.id.uuidString)
                                }
                            }
                            Divider()
                        #endif
                    }

                    Group {
                        ScrollView(.horizontal) {
                            Text(document.fileURL.lastPathComponent)
                        }
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
            }
            .padding()
        } else {
            Text("No saved data")
                .padding()
        }
    }
}

 struct NoteInformation_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(TargetPreviewDevice.allCases) { deviceName in
            NoteInformation(document: nil)
                .previewDevice(PreviewDevice(rawValue: deviceName.rawValue))
                .previewDisplayName(deviceName.rawValue)
        }
    }
 }
