//
//  EventNames.swift
//  LikePaper
//
//  Created by nakajima on 2020/10/02.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import Foundation

enum EventNames: String {
    case loadedFromiCloud
    
    func eventName() -> Notification.Name {
        return Notification.Name(rawValue)
    }
}
