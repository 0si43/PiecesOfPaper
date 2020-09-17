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

    private var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker!
    private var isHiddenStatusBar = false
    override var prefersStatusBarHidden: Bool {
        return isHiddenStatusBar
    }
    // 既存のノート編集の場合、CollectionViewがセットする
    var drawing: PKDrawing?
    var indexAtCollectionView: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView = PKCanvasView(frame: view.frame)
        if let drawing = drawing {
            canvasView.drawing = drawing
        }
        view.addSubview(canvasView)
        canvasView.allowsFingerDrawing = false
        canvasView.isScrollEnabled = true
        canvasView.alwaysBounceHorizontal = true
        canvasView.alwaysBounceVertical = true
        addPalette()
        // 上部のバーは全て非表示にする
        setStatusBar(hidden: true)
        setNavigationBar(hidden: true)
    }
    
    private func addPalette() {
        if let window = UIApplication.shared.windows.first,
            let toolPicker = PKToolPicker.shared(for: window) {
            self.toolPicker = toolPicker
            self.toolPicker.addObserver(canvasView)
            self.toolPicker.addObserver(self)
            canvasView.becomeFirstResponder()
            self.toolPicker.selectedTool = PKInkingTool(.pen, color: .black, width: 1)
        }
    }
    
    @IBAction func tapAction(_ sender: Any) {
        toggleAllToolsVisibility()
    }
    
    private func toggleAllToolsVisibility() {
        let hidden = !isHiddenStatusBar
        setStatusBar(hidden: hidden)
        setNavigationBar(hidden: hidden)
        toolPicker.setVisible(!hidden, forFirstResponder: canvasView) // toolPickerはvisible指定なので、hiddenを反転させる
    }
    
    private func setStatusBar(hidden: Bool) {
        isHiddenStatusBar = hidden
    }
    
    private func setNavigationBar(hidden: Bool) {
        navigationController?.setNavigationBarHidden(hidden, animated: true)
    }
    
    @IBAction func saveAction(_ sender: Any) {
        guard let collectionViewController = thumbnailCollectionViewController() else { return }
        collectionViewController.saveDrawingOnCanvas(drawing: canvasView.drawing,
                                                     index: indexAtCollectionView)
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if let index = indexAtCollectionView {
            alertWhenCancel(index: index)
        } else {
            dismiss(animated: false, completion: nil)
        }
    }
    
    private func thumbnailCollectionViewController() -> ThumbnailCollectionViewController? {
        guard let navigationController = presentingViewController as? UINavigationController,
                let collectionViewController = navigationController.topViewController as? ThumbnailCollectionViewController else { return nil }
        return collectionViewController
    }
    
    private func alertWhenCancel(index: Int) {
        let alertController = UIAlertController(title: "",
                                      message: "Your changes will be discarded",
                                      preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "OK",
                                         style: .destructive) {[weak self](action) in
            self?.dismiss(animated: false, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {(action) in return }
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func shareAction(_ sender: UIBarButtonItem) {
        let drawing = canvasView.drawing
        let image = drawing.image(from: drawing.bounds, scale: 1.0)
        let activityViewController = UIActivityViewController(activityItems: [image],
                                                              applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func fingerDrawingAction(_ sender: UIBarButtonItem) {
        canvasView.allowsFingerDrawing.toggle()
        sender.image = canvasView.allowsFingerDrawing ? UIImage(systemName: "hand.draw.fill") : UIImage(systemName: "hand.draw")
    }
}
