//
//  ViewController.swift
//  LikeAPaper
//
//  Created by nakajima on 2020/04/03.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import UIKit
import PencilKit

class CanvasViewController: UIViewController {

    var statusBarHidden = false
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    override func viewWillAppear(_ animated: Bool) {
        upSideBarHidden(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let canvas = PKCanvasView(frame: view.frame)
        view.addSubview(canvas)
        canvas.tool = PKInkingTool(.pen, color: .black, width: 1)
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))        
//        gesture.direction = .up
//        view.addGestureRecognizer(gesture)
        gesture.direction = .down
        view.addGestureRecognizer(gesture)
    }
    
    @objc func didSwipe(sender: UISwipeGestureRecognizer) {
        switch sender.direction {
//        case .up:
//            upSideBarHidden(true)
        case .down:
            upSideBarHidden(false)
        default:
            return
        }
    }
    
    private func upSideBarHidden(_ isHidden: Bool) {
        statusBarHidden = isHidden
        navigationController?.setNavigationBarHidden(isHidden, animated: true)
    }
}

