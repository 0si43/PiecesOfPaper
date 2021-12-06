//
//  TagListToNote.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/05.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct TagListToNote: View {
    @ObservedObject var viewModel = TagListToNoteViewModel()

    var body: some View {
        if viewModel.noteDocument != nil {
            List {
                DeletableTagHStack()
                    .environmentObject(viewModel)
                Section(header: Text("Select tag which you want to add")) {
                    ForEach(viewModel.tagsNotToNote, id: \.id) { tag in
                        Tag(entity: tag)
                            .onTapGesture {
                                viewModel.add(tagName: tag.name)
                            }
                    }
                }
            }
        } else {
            Text("Couldn't found note data")
        }
    }
}

struct TagListToNote_Previews: PreviewProvider {
    static var previews: some View {
        TagListToNote()
    }
}
