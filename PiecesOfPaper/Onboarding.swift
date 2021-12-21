//
//  Onboarding.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2021/12/20.
//  Copyright © 2021 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct Onboarding: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack {
                    Group {
                        Text("What's new")
                            .font(.largeTitle)
                            .bold()
                            .padding()
                        Text("Pieces of Paper is now version 3.0.0")
                            .font(.caption)
                    }
                    VStack(alignment: .leading) {
                        NewFeature(image: Image(systemName: "sparkles"),
                                   imageColor: Color.yellow,
                                   title: Text("Replace User Interface"),
                                   message: Text("Don't be surprised. Pieces of Paper changed up its look"))
                        NewFeature(image: Image(systemName: "archivebox"),
                                   imageColor: Color.red,
                                   title: Text("Archive"),
                                   message: Text("(New Feature) You can attach some tags to notes"))
                        NewFeature(image: Image(systemName: "tag"),
                                   imageColor: Color.green,
                                   title: Text("Tag"),
                                   message: Text("(New Feature) You can attach some tags to notes"))
                        NewFeature(image: Image(systemName: "arrow.up.arrow.down.circle"),
                                   imageColor: Color.purple,
                                   title: Text("Sort & Filter"),
                                   message: Text("(New Feature) Sort and filter is now available"))
                        NewFeature(image: Image(systemName: "doc"),
                                   imageColor: Color.blue,
                                   title: Text("File Format Change"),
                                   message: Text("From now on, one note is saved as one file"))
                    }
                }
                    .padding(.horizontal)

                    Divider()
                        Text(
                        "⚠️If you have old format file(named drawings.plist), convert will start automatically. " +
                        "Your notes will be split. (Note:) Syncing with iCloud is sometimes unstable. " +
                        "If you see weird behavior, please open Files app and manage file state."
                        )
                        .font(.footnote)
                        .padding(.horizontal)
                    Spacer()
            }
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("Got it")
                    .foregroundColor(.white)
                    .frame(minWidth: 300, minHeight: 50)
                    .background(Color.blue)
                    .cornerRadius(5.0)
                    .contentShape(RoundedRectangle(cornerRadius: 5.0))
            }
        }
        .padding()
    }
}

private struct NewFeature: View {
    let image: Image
    let imageColor: Color
    let title: Text
    let message: Text

    var body: some View {
        HStack(spacing: 8) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .padding()
                .foregroundColor(imageColor)
            VStack(alignment: .leading, spacing: 4) {
                title
                    .font(.title3)
                    .bold()
                message
                    .font(.footnote)
            }
        }
    }
}

struct Onboarding_Previews: PreviewProvider {
    static var previews: some View {
        Onboarding()
    }
}
