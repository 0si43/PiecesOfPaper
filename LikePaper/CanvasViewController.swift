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
    private var toolPicker: PKToolPicker = {
        if #available(iOS 14.0, *) {
            return PKToolPicker()
        } else {
            return PKToolPicker.shared(for: UIApplication.shared.windows.first!)!
        }
    }()
    
    private let defaultTool = PKInkingTool(.pen, color: .black, width: 1)
    
    private var isHiddenStatusBar = false
    override var prefersStatusBarHidden: Bool {
        return isHiddenStatusBar
    }
    // 既存のノート編集の場合、CollectionViewがセットする
    var drawing: PKDrawing?
    var indexAtCollectionView: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingCanvas()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        canvasView.frame.size = size
    }
    
    private func settingCanvas() {
        canvasView = PKCanvasView(frame: view.frame)
        if let drawing = drawing {
            canvasView.drawing = drawing
            if drawing.bounds.origin != CGPoint.zero {
                canvasView.contentOffset = drawing.bounds.origin
            }
            if canvasView.frame.size.width < drawing.bounds.size.width {
                canvasView.contentSize.width = drawing.bounds.size.width
            } else {
                canvasView.contentSize.width = canvasView.frame.size.width
            }
            if canvasView.frame.size.height < drawing.bounds.size.height {
                canvasView.contentSize.height = drawing.bounds.size.height
            } else {
                canvasView.contentSize.height = canvasView.frame.size.height
            }
        }
        view.addSubview(canvasView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
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
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(self)
        canvasView.becomeFirstResponder()
        toolPicker.selectedTool = defaultTool
    }
    
    @IBAction func tapAction(_ sender: Any) {
        toggleAllToolsVisibility()
    }
    
    private func toggleAllToolsVisibility() {
        let hidden = !isHiddenStatusBar
        setStatusBar(hidden: hidden)
        setNavigationBar(hidden: hidden)
        toolPicker.setVisible(!hidden, forFirstResponder: canvasView) // toolPickerはvisible指定なので、hiddenを反転させる
        canvasView.becomeFirstResponder()
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
        let image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
        let activityViewController = UIActivityViewController(activityItems: [image],
                                                              applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func fingerDrawingAction(_ sender: UIBarButtonItem) {
        if #available(iOS 14.0, *) {
            canvasView.drawingPolicy = canvasView.drawingPolicy == .anyInput ? .pencilOnly : .anyInput
        } else {
            canvasView.allowsFingerDrawing.toggle()
        }
        sender.image = canvasView.allowsFingerDrawing ? UIImage(systemName: "hand.draw.fill") : UIImage(systemName: "hand.draw")
    }
}
