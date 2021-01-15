//
//  ViewController.swift
//  LikeAPaper
//
//  Created by nakajima on 2020/04/03.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import UIKit
import PencilKit

final class CanvasViewController: UIViewController {

    private var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker = {
        if #available(iOS 14.0, *) {
            return PKToolPicker()
        } else {
            return PKToolPicker.shared(for: UIApplication.shared.windows.first!)!
        }
    }()
    
    private let defaultTool = PKInkingTool(.pen, color: .black, width: 1)
    // for double tap action on Apple Pencil
    private var currentTool: PKTool?
    private var previousTool: PKTool?
    
    private var isHiddenStatusBar = false
    override var prefersStatusBarHidden: Bool {
        return isHiddenStatusBar
    }
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var autosaveButton: UIBarButtonItem!
    
    // if a note is exist、a CollectionView set below properties
    var drawing: PKDrawing?
    var indexAtCollectionView: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingCanvas()
        guard let thumbnailCollectionViewController = thumbnailCollectionViewController() else { return }
        if thumbnailCollectionViewController.didDocumentOpen {
            enabledSaveButton()
        }
        addPencilInteraction()
        settingNotificationCenter()
        settingMinumumZoomLevelIfDeviceIsiPhone()
    }
    
    private func settingCanvas() {
        canvasView = PKCanvasView(frame: view.frame)
        canvasView.delegate = self
        if let drawing = drawing {
            canvasView.drawing = drawing
            adjustToCanvas(drawing: drawing)
        }
        view.addSubview(canvasView)
    }
    
    private func settingNotificationCenter() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enabledSaveButton),
                                               name: EventNames.oepnedDocument.eventName(),
                                               object: nil)
    }
    
    private func settingMinumumZoomLevelIfDeviceIsiPhone() {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: canvasView.minimumZoomScale = 0.3
        default: return
        }
    }
    
    @objc private func enabledSaveButton() {
        saveButton.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAutoSaveButton()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        canvasView.frame.size = size
    }
    
    private func updateAutoSaveButton() {
        autosaveButton.title = Autosave.buttonTitle
    }
    
    private func adjustToCanvas(drawing: PKDrawing) {
        if canvasView.frame.size.width < drawing.bounds.size.width {
            canvasView.contentSize.width = drawing.bounds.size.width + 100.0
        } else {
            canvasView.contentSize.width = canvasView.frame.size.width
        }
        if canvasView.frame.size.height < drawing.bounds.size.height {
            canvasView.contentSize.height = drawing.bounds.size.height + 100.0
        } else {
            canvasView.contentSize.height = canvasView.frame.size.height
        }
        // if drawing is far from canvasView's origin, add its distance
        // surprisingly, no writing PKDrawing return origin(Infinite, Infinite)
        if !drawing.bounds.origin.x.isInfinite {
            canvasView.contentSize.width += drawing.bounds.origin.x
        }
        if !drawing.bounds.origin.y.isInfinite {
            canvasView.contentSize.height += drawing.bounds.origin.y
        }
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
        _ = collectionViewController.saveDrawingOnCanvas(drawing: canvasView.drawing, index: indexAtCollectionView)
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
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
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
    
    @IBAction func autosaveChangeAction(_ sender: UIBarButtonItem) {
        Autosave.isDisabled.toggle()
        autosaveButton.title = Autosave.buttonTitle
    }
}

// MARK: PKToolPickerObserver
extension CanvasViewController: PKToolPickerObserver {
    private func addPalette() {
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(self)
        canvasView.becomeFirstResponder()
        toolPicker.selectedTool = defaultTool
        currentTool = defaultTool
    }
    
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        previousTool = currentTool
        currentTool = toolPicker.selectedTool
    }
}

// MARK: PKCanvasViewDelegate
extension CanvasViewController: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard let collectionViewController = thumbnailCollectionViewController() else { return }
        guard collectionViewController.didDocumentOpen else { return }
        guard !Autosave.isDisabled else { return }
        let index = collectionViewController.autosaveDrawingOnCanvas(drawing: canvasView.drawing, index: indexAtCollectionView)
        
        if indexAtCollectionView != index {
            indexAtCollectionView = index
        }
    }
}

// MARK: UIPencilInteractionDelegate
extension CanvasViewController: UIPencilInteractionDelegate {
    private func addPencilInteraction() {
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = self
        canvasView.addInteraction(pencilInteraction)
    }
    
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        guard !toolPicker.isVisible else { return }
        let action = UIPencilInteraction.preferredTapAction
        switch action {
        case .switchPrevious:   switchPreviousTool()
        case .switchEraser:     switchEraser()
        case .showColorPalette: toggleAllToolsVisibility()
        case .ignore:           return
        default:                return
        }
    }
    
    private func switchPreviousTool() {
        toolPicker.selectedTool = previousTool ?? defaultTool
    }
    
    private func switchEraser() {
        if currentTool is PKEraserTool {
            toolPicker.selectedTool = previousTool ?? defaultTool
        } else {
            toolPicker.selectedTool = PKEraserTool(.vector) // Maybe user could choice his/her preference
        }
    }
}
