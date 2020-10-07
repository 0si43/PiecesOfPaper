//
//  ThumbnailCollectionViewController.swift
//  LikeAPaper
//
//  Created by nakajima on 2020/04/19.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import UIKit
import PencilKit

final class ThumbnailCollectionViewController: UICollectionViewController, DocumentManagerDelegate {
    private let reuseIdentifier = "ThumbnailCollectionViewCell"
    private var drawings = [PKDrawing]()
    // User made new drawings before load frome iCloud, set here and need to merge
    private var tempolaryDrawings: [PKDrawing]?
    private var firstLunch = true
    // update DocumentManager when first file is opened successfully
    var didDocumentOpen = false {
        didSet {
            NotificationCenter.default.post(name: EventNames.oepnedDocument.eventName(), object: nil)
            if let tempolaryDrawings = tempolaryDrawings {
                documentManager.drawings += tempolaryDrawings
            } else {
                reload()
            }
        }
    }
    
    // an index of a tapped note
    private var selectedIndex: Int?
    
    private var documentManager: DocumentManager!
    @IBOutlet weak var autosaveButton: UIBarButtonItem!
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            reload()
        }
    }
    
    @objc private func reloadIfNeeded() {
        /*
         UIDocument.State
        .normal:            0b00000000 -> 0
        .closed:            0b00000001 -> 1
        .inConflict:        0b00000010 -> 2
        .savingError:       0b00000100 -> 4
        .editingDisabled:   0b00001000 -> 8
        .progressAvailable: 0b00010000 -> 16
         
        State is OptionSet. Rawvalue can be some combination.
        For example, .inConflict & .progressAvailable equales 20
         */
        print(documentManager.document.documentState.rawValue)
        if documentManager.document.documentState == .normal {
            reload()
        }
    }
    
    private func reload() {
        drawings = documentManager.drawings
        collectionView?.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        documentManager = DocumentManager(delegate: self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadIfNeeded),
                                               name: UIDocument.stateChangedNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        autosaveButton.title = Autosave.buttonTitle
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard firstLunch else { return }
        performSegue(withIdentifier: "toCanvasView", sender: self)
        firstLunch = false
    }

    @IBAction func newCanvas(_ sender: Any) {
        performSegue(withIdentifier: "toCanvasView", sender: self)
    }
    
    @IBAction func update(_ sender: Any) {
        reload()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController,
            let canvas = navigationController.topViewController as? CanvasViewController {
            canvas.indexAtCollectionView = selectedIndex
            guard let index = selectedIndex, index < drawings.endIndex else { return }
            canvas.drawing = drawings[index]
        }
        selectedIndex = nil
    }
    
    // if new, you pass an index as nil
    func saveDrawingOnCanvas(drawing: PKDrawing, index: Int?) -> Int {
        if let index = index {
            addExistDrawing(drawing: drawing, index: index)
        } else {
            addNewDrawing(drawing: drawing)
        }
        documentManager.drawings = drawings
        documentManager.save()
        return index ?? drawings.endIndex - 1
    }
    
    // if new, you pass an index as nil
    func autosaveDrawingOnCanvas(drawing: PKDrawing, index: Int?) -> Int {
        if let index = index {
            addExistDrawing(drawing: drawing, index: index)
        } else {
            addNewDrawing(drawing: drawing)
        }
        documentManager.drawings = drawings
        documentManager.autosave()
        return index ?? drawings.endIndex - 1
    }
    
    private func addExistDrawing(drawing: PKDrawing, index: Int) {
        guard index < drawings.endIndex else { return }
        drawings[index] = drawing
        let indexPath = IndexPath(row: index, section: 0)
        collectionView.reloadItems(at: [indexPath])
    }
    
    private func addNewDrawing(drawing: PKDrawing) {
        let numberOfCells = collectionView.numberOfItems(inSection: 0)
        if didDocumentOpen {
            drawings.append(drawing)
        } else {
            tempolaryDrawings?.append(drawing)
        }
        let indexPath = IndexPath(row: numberOfCells, section: 0)
        collectionView.insertItems(at: [indexPath])
    }

    
    @IBAction func autosaveChangeAction(_ sender: UIBarButtonItem) {
        Autosave.isDisabled.toggle()
        autosaveButton.title = Autosave.buttonTitle
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return didDocumentOpen ? drawings.count : tempolaryDrawings?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ThumbnailCollectionViewCell else { fatalError("Unexpected cell type.") }
        let drawing = drawings[indexPath.row]
        // When the scale was 2.0, the line was jagged(collectionView did something?)
        let image = drawing.image(from: drawing.bounds, scale: 0.6)
        cell.imageView.image = image
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        performSegue(withIdentifier: "toCanvasView", sender: self)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let index = indexPath.row
        let actionProvider: ([UIMenuElement]) -> UIMenu? = { _ in
            let share = UIAction(title: "Share",
                                 image: UIImage(systemName: "square.and.arrow.up"))
                                {[weak self] _ in self?.shareAction(index: index, point: point) }
            let copy = UIAction(title: "Copy",
                                image: UIImage(systemName: "doc.on.doc"))
                                {[weak self] _ in self?.copyAction(index: index) }
            let delete = UIAction(title: "Delete",
                                  image: UIImage(systemName: "trash"),
                                  attributes: .destructive)
                                {[weak self] _ in self?.deleteAction(index: index) }
            return UIMenu(title: "", image: nil, identifier: nil, children: [copy, delete, share])
        }
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: actionProvider)
    }
    
    // MARK: actions when UIMenu is tapped
    private func shareAction(index: Int, point: CGPoint) {
        guard index <= drawings.endIndex else { return }
        let drawing = drawings[index]
        let shareImage = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
        let activityViewController = UIActivityViewController(activityItems: [shareImage], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = collectionView
        activityViewController.popoverPresentationController?.sourceRect = CGRect(origin: point, size: .zero)
        present(activityViewController, animated: true, completion: nil)
    }
    
    private func copyAction(index: Int) {
        guard index <= drawings.endIndex else { return }
        drawings.append(drawings[index])
        documentManager.drawings = drawings
        documentManager.save()
        let indexPath = IndexPath(row: collectionView.numberOfItems(inSection: 0), section: 0)
        collectionView.insertItems(at: [indexPath])
    }
    
    private func deleteAction(index: Int) {
        guard index < drawings.endIndex else { return }
        drawings.remove(at: index)
        documentManager.drawings = drawings
        documentManager.save()
        collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        guard index != drawings.endIndex else { return } // 削除した要素が配列の末尾だった場合はリロード不要
        let indexPaths = (index ..< drawings.endIndex).map {
            return IndexPath(row: $0, section: 0)
        }
        collectionView.reloadItems(at: indexPaths)
    }
}
