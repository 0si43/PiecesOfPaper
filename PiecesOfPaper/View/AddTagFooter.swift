//
//  AddTagFooter.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/06.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct AddTagFooter: View {
    @Binding var tags: [TagEntity]
    @State private var tagName: String = "🏷Tag"
    private var tagColor: CodableUIColor {
        CodableUIColor(uiColor: UIColor(color))
    }

    @State private var color: Color = .blue
    @State var isTapped = false
    private var tagEntity: TagEntity {
        TagEntity(name: tagName, color: tagColor)
    }

    var body: some View {
        HStack {
            Spacer()
            Image(systemName: "plus.circle")
                .resizable()
                .frame(width: 24.0, height: 24.0)
                .foregroundColor(.blue)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isTapped.toggle()
        }
        .sheet(isPresented: $isTapped) {
            NavigationView {
                VStack {
                    Tag(entity: tagEntity)
                    HStack {
                        Text("Tag Name: ")
                        TextField("", text: $tagName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    ColorPicker("Tag Color", selection: $color, supportsOpacity: false)
                    .padding()
                    Spacer()
                }
                .navigationBarItems(leading:
                    Button(action: cancel) {
                        Text("Cancel")
                        .foregroundColor(.red)
                    }
                )
                .navigationBarItems(trailing:
                    Button(action: save) {
                        Text("Done")
                    }
                )
            }
        }
    }

    func cancel() {
        isTapped.toggle()
    }

    func save() {
        tags.append(tagEntity)
        isTapped.toggle()
    }
}

struct AddTagFooter_Previews: PreviewProvider {
    @State static var tags = [TagEntity(name: "test", color: CodableUIColor(uiColor: .red))]

    static var previews: some View {
        AddTagFooter(tags: $tags)
    }
}
