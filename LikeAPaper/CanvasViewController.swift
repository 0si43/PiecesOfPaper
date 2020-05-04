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
    var indexAtCollectionView: Int?
    
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
        guard let collectionViewController = thumbnailCollectionViewController() else { return }
        if let index = indexAtCollectionView {
            collectionViewController.drawings[index] = canvas.drawing
            let indexPath = IndexPath(row: index, section: 0)
            collectionViewController.collectionView?.reloadItems(at: [indexPath])
        } else {
            let numberOfCells = collectionViewController.collectionView.numberOfItems(inSection: 0)
            collectionViewController.drawings.append(canvas.drawing)
            let indexPath = IndexPath(row: numberOfCells, section: 0)
            collectionViewController.collectionView.insertItems(at: [indexPath])
        }
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        if let index = indexAtCollectionView {
            alertWhenDelete(index: index)
        } else {
            dismiss(animated: false, completion: nil)
        }
    }
    
    private func thumbnailCollectionViewController() -> ThumbnailCollectionViewController? {
        guard let navigationController = presentingViewController as? UINavigationController,
                let collectionViewController = navigationController.topViewController as? ThumbnailCollectionViewController else { return nil }
        return collectionViewController
    }
    
    private func alertWhenDelete(index: Int) {
        let alertController = UIAlertController(title: "",
                                      message: "本当に削除しますか？",
                                      preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "OK", style: .destructive) {[weak self](action) in
            let collectionViewController = self?.thumbnailCollectionViewController()
            collectionViewController?.drawings.remove(at: index)
            let indexPath = IndexPath(row: index, section: 0)
            collectionViewController?.collectionView?.deleteItems(at: [indexPath])
            self?.dismiss(animated: false, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {(action) in return }
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func shareAction(_ sender: UIBarButtonItem) {
        let shareImage = canvas.drawing.image(from: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), scale: 1.0)
        let activityViewController = UIActivityViewController(activityItems: [shareImage], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
}
