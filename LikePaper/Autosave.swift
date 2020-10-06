//
//  AutoSave.swift
//  LikePaper
//
//  Created by nakajima on 2020/10/06.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import Foundation

struct Autosave {
    static let key = "is autosave disabled"
    static var buttonTitle: String {
        let state = Autosave.isDisabled ? "Off" :  "On"
        return "Autosave: " + state
    }
    
    // UserDefaults retrun flase if the specified key doesn‘t exist, so this proerty is "isDisabled"
    // (I want it to be autosave enabled first time)
    static var isDisabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
