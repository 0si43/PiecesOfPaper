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
            Group {
                Text("What's new")
                    .font(.largeTitle)
                    .padding()
                Text("Pieces of Paper is now version 3.0.0")
                    .padding()
            }
            HStack {
                Image(systemName: "sparkles")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .padding()
                    .foregroundColor(Color.yellow)
                VStack(alignment: .leading) {
                    Text("Totally Replace User Interface")
                        .font(.title3)
                    Text("Don't be surprised. Pieces of Paper changed up its look")
                        .font(.body)
                }
                Spacer()
            }
            HStack {
                Image(systemName: "tag")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .padding()
                    .foregroundColor(Color.green)
                VStack(alignment: .leading) {
                    Text("New Feature: Tag")
                        .font(.title3)
                    Text("You can attach some tags to notes. It's will be helpful to arrange your data")
                        .font(.body)
                }
                Spacer()
            }
            HStack {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .padding()
                    .foregroundColor(Color.blue)
                VStack(alignment: .leading) {
                    Text("New Feature: Sort & Filter")
                        .font(.title3)
                    Text("Sort and filter is now available")
                        .font(.body)
                }
                Spacer()
            }
            HStack {
                Image(systemName: "folder")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .padding()
                    .foregroundColor(Color.blue)
                VStack(alignment: .leading) {
                    Text("Data Format Change")
                        .font(.title3)
                    Text("Before now, notes data is saved as one file. It's inconvenient. From now on, one note is saved as one file")
                        .font(.body)
                }
                Spacer()
            }
            Divider()
            ScrollView(.vertical) {
                Text("""
                ⚠️If you have old format file(named drawings.plist), convert will start automatically.
                Your notes separated each file. Syncing with iCloud is sometimes unstable.
                If you feel like weird behavior, please open Files app and manage file state.
                """)
                    .padding()
            }
            Spacer()
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("Got it")
                    .foregroundColor(.white)
                    .frame(minWidth: 300, minHeight: 50)
                    .background(Color.blue)
                    .cornerRadius(5.0)
                    .contentShape(RoundedRectangle(cornerRadius: 5.0))
            }
            Spacer()
        }
        .padding()
    }
}

struct Onboarding_Previews: PreviewProvider {
    static var previews: some View {
        Onboarding()
    }
}
