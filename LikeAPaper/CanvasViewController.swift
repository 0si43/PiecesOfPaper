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
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
        statusBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let canvas = PKCanvasView(frame: view.frame)
        view.addSubview(canvas)
        canvas.tool = PKInkingTool(.pen, color: .black, width: 1)
        navigationController?.hidesBarsOnSwipe = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
}

