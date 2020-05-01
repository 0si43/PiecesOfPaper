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
    var canvas: PKCanvasView!
    
    override func viewWillAppear(_ animated: Bool) {
        upSideBarHidden(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canvas = PKCanvasView(frame: view.frame)
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
    
    @IBAction func saveAction(_ sender: Any) {
        performSegue(withIdentifier: "toThumbnailCollectionViewController", sender: self)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "toThumbnailCollectionViewController" else { return }
        let view = segue.destination as? ThumbnailCollectionViewController
        view?.loadDataModel()
        view?.dataModel.drawings.append(canvas.drawing)
        view?.saveDataModel()
    }
}

