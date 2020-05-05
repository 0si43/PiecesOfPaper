//
//  AppDelegate.swift
//  LikeAPaper
//
//  Created by nakajima on 2020/04/03.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import UIKit
import PencilKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var drawings = [PKDrawing]()
    
    func applicationWillResignActive(_ application: UIApplication) {
        let dataModel = DataModel(drawings: drawings)
        dataModel.save(drawings: drawings)
    }
}

