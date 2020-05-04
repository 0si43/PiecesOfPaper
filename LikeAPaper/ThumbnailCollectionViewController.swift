//
//  ThumbnailCollectionViewController.swift
//  LikeAPaper
//
//  Created by nakajima on 2020/04/19.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import UIKit
import PencilKit

private let reuseIdentifier = "ThumbnailCollectionViewCell"

class ThumbnailCollectionViewController: UICollectionViewController {
    
    let dataModel = DataModel()
    var drawings = [PKDrawing]() {
        didSet {
            appDelegate?.drawings = drawings
        }
    }
    
    var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    // タップしたノートのIndex
    var selectedIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.drawings = dataModel.drawings
        performSegue(withIdentifier: "toCanvasView", sender: self)
    }

    @IBAction func newCanvas(_ sender: Any) {
        performSegue(withIdentifier: "toCanvasView", sender: self)
    }
    
    @IBAction func update(_ sender: Any) {
        collectionView?.reloadData()
    }
    
    @IBAction func daleteData(_ sender: Any) {
        let numberOfCells = collectionView.numberOfItems(inSection: 0)
        let indexPath = IndexPath(row: numberOfCells - 1, section: 0)
        drawings.removeLast()
        collectionView?.deleteItems(at: [indexPath])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController,
            let canvas = navigationController.topViewController as? CanvasViewController {
            canvas.indexAtCollectionView = selectedIndex
            guard let index = selectedIndex,
                index < drawings.count else { return }
            canvas.drawing = drawings[index]
        }
        selectedIndex = nil
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return drawings.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ThumbnailCollectionViewCell else { fatalError("Unexpected cell type.") }
        let drawing = drawings[indexPath.row].image(from: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), scale: 1.0)
        cell.imageView.image = drawing
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        performSegue(withIdentifier: "toCanvasView", sender: self)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
            
        // ①プレビューの定義
//            let previewProvider: () -> PreviewViewController? = { [unowned self] in
//                return PreviewViewController(image: self.images[indexPath.row])
//            }
        let actionProvider: ([UIMenuElement]) -> UIMenu? = { _ in
            let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { _ in
                // some action
            }
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
                // some action
            }
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                // some action
            }
            return UIMenu(title: "", image: nil, identifier: nil, children: [copy, delete, share])
        }

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: actionProvider)
    }
}
