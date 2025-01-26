//
//  TutorialView.swift
//  PiecesOfPaper
//
//  Created by Nakajima on 2025/01/26.
//  Copyright © 2025 Tsuyoshi Nakajima. All rights reserved.
//

import SwiftUI

struct TutorialView: View {
    var body: some View {
        ScrollView {
            Text("""
            **Basis**

            - Pieces of Paper is designed specifically for iPad and Apple Pencil
            - The iOS app exists but offers limited practical value
            - When you launch the app, it displays a blank white canvas across the entire screen. You can immediately start writing with your Apple Pencil. Double-tapping the Apple Pencil switches to eraser mode
            - Tapping the screen with your finger reveals additional tools, and pressing the Done button in the top right closes the window
            - The app features auto-save functionality, which can be disabled in settings

            **Data Management**

            - By default, this app uses your iCloud storage. This enables data synchronization across devices
            - You can also use local storage without iCloud. Turn it off in Setting > Enable iCloud.
            - There is one major issue with iCloud integration. You cannot download files created on other devices directly from Pieces of Paper. Please note that you need to open the Files app to sync them

            **Archive**

            - The app includes an archive feature
            - It's designed to work like Gmail's archive system
              - Maybe you don't use or dislike
            - Archiving an item doesn't delete the actual file - additional steps are required for permanent deletion

            **Tag**

            - The app includes a tag feature
            - You can add/remove tags via Tag List
            - Tag list files are stored in iCloud or local storage
            - The path is Library/taglist.json
            - If synchronization issues occur during device migration or iCloud setting changes, manually manage storage and select the appropriate file

            **Infinite Canvas**

            - You can use infinite canvas by default
            - Write something on the bottom-right corner of your note to expand the canvas
            - Toggle this feature on/off in settings
            
            **Important Notes**

            - I have identified an issue where files created on iCloud may become inaccessible. While the exact conditions are unknown, this can potentially cause the entire app to hang.
            - In the developer's environment, this occurred after creating more than 500 files. However, I've confirmed that other files remain usable once the problematic files are removed.
            - If you encounter this issue, you can recover by creating a backup folder in your iCloud storage, backing up all files from Pieces of Paper's Inbox, and then attempting to delete everything in Inbox

            **FAQ**

            Q: Is this app free?
            A: Yes, it's **free**. In fact, all the source code is publicly available.

            Q: Where should I report bugs?
            A: Please create an issue on [GitHub Repository](https://github.com/0si43/PiecesOfPaper) . However, I cannot promise to fix every issue (as this is a free app!). If you're a developer, I'd be delighted to receive your pull requests!😁

            Q: This app's bug ruined my notes! I worked hard on those notes and now they're gone! This is terrible!
            A: Sorry for your inconvenience. Please note that Pieces of Paper is developed by an individual developer and offered as a free app.

               While I'm confident in the app's usability, I cannot guarantee 100% stability. For important documents, I cannot take responsibility for any data loss. I recommend regularly exporting your work as image files or using a more reliable app for critical documents.
            """)
            .padding()
        }
    }
}

#Preview {
    TutorialView()
}
