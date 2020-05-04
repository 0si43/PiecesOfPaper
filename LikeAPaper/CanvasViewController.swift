//
//  ViewController.swift
//  LikeAPaper
//
//  Created by nakajima on 2020/04/03.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import UIKit
import PencilKit

class CanvasViewController: UIViewController, PKToolPickerObserver {

    private var statusBarHidden = false
    // 既存のノート編集の場合、CollectionViewがセットする
    var drawing: PKDrawing?
    var indexAtCollectionView: Int?
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    private var canvasView: PKCanvasView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView = PKCanvasView(frame: view.frame)
        if let drawing = drawing {
            canvasView.drawing = drawing
        }
        view.addSubview(canvasView)
        canvasView.isScrollEnabled = true
        canvasView.alwaysBounceHorizontal = true
        canvasView.alwaysBounceVertical = true
        if let window = UIApplication.shared.windows.first,
            let toolPicker = PKToolPicker.shared(for: window) {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            toolPicker.addObserver(self)
            canvasView.becomeFirstResponder()
            toolPicker.selectedTool = PKInkingTool(.pen, color: .black, width: 1)
        }
    }
    
    override func viewWillLayoutSubviews() {
        upSideBarHidden(true)
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
            collectionViewController.drawings[index] = canvasView.drawing
            let indexPath = IndexPath(row: index, section: 0)
            collectionViewController.collectionView?.reloadItems(at: [indexPath])
        } else {
            let numberOfCells = collectionViewController.collectionView.numberOfItems(inSection: 0)
            collectionViewController.drawings.append(canvasView.drawing)
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
        let drawing = canvasView.drawing
        let shareImage = drawing.image(from: drawing.bounds, scale: 1.0)
        let activityViewController = UIActivityViewController(activityItems: [shareImage], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
}
