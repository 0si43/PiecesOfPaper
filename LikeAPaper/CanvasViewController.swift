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

    private var statusBarHidden = false
    var drawing: PKDrawing?
    
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
        if let drawing = drawing {
            canvas.drawing = drawing
        }
        view.addSubview(canvas)
        canvas.tool = PKInkingTool(.pen, color: .black, width: 1)
    }
    
    @IBAction func swipeUp(_ sender: Any) {
        upSideBarHidden(true)
    }
    
    @IBAction func swipeDown(_ sender: Any) {
        upSideBarHidden(false)
    }
    
    
    private func upSideBarHidden(_ isHidden: Bool) {
        statusBarHidden = isHidden
        navigationController?.setNavigationBarHidden(isHidden, animated: true)
    }
    
    @IBAction func saveAction(_ sender: Any) {
        if let navigationController = presentingViewController as? UINavigationController,
            let collectionViewController = navigationController.topViewController as? ThumbnailCollectionViewController {
            collectionViewController.dataModel.drawings.append(canvas.drawing)
        }
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func shareAction(_ sender: UIBarButtonItem) {
        let shareImage = canvas.drawing.image(from: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), scale: 1.0)
        let activityViewController = UIActivityViewController(activityItems: [shareImage], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
}
