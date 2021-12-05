//
//  EventNames.swift
//  LikePaper
//
//  Created by Nakajima on 2020/10/02.
//  Copyright © 2020 Tsuyoshi Nakajima. All rights reserved.
//

import Foundation

enum EventNames: String {
    case oepnedDocument

    func eventName() -> Notification.Name {
        Notification.Name(rawValue)
    }
}
