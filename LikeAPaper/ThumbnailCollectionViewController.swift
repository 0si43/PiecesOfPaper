//
//  ThumbnailCollectionViewController.swift
//  LikeAPaper
//
//  Created by nakajima on 2020/04/19.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import UIKit
import PencilKit

class ThumbnailCollectionViewController: UICollectionViewController {
    
    private let reuseIdentifier = "ThumbnailCollectionViewCell"
    private let dataModel = DataModel()
    private var drawings = [PKDrawing]() {
        didSet { appDelegate?.drawings = drawings }
    }
    
    private var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    // タップしたノートのIndex
    private var selectedIndex: Int?
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            reload()
        }
    }
    
    private func reload() {
        collectionView?.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.drawings = dataModel.drawings
        performSegue(withIdentifier: "toCanvasView", sender: self)
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
    
    // 新規作成の場合、indexはnilで渡す
    func saveDrawingOnCanvas(drawing: PKDrawing, index: Int?) {
        if let index = index {
            guard index < drawings.endIndex else { return }
            drawings[index] = drawing
            let indexPath = IndexPath(row: index, section: 0)
            collectionView.reloadItems(at: [indexPath])
        } else {
            let numberOfCells = collectionView.numberOfItems(inSection: 0)
            drawings.append(drawing)
            let indexPath = IndexPath(row: numberOfCells, section: 0)
            collectionView.insertItems(at: [indexPath])
        }
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
        let drawing = drawings[indexPath.row]
        let image = drawing.image(from: drawing.bounds, scale: 1.0)
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
    
    // UIMenuタップ時のアクション
    private func shareAction(index: Int, point: CGPoint) {
        guard index <= drawings.endIndex else { return }
        let drawing = drawings[index]
        let shareImage = drawing.image(from: drawing.bounds, scale: 1.0)
        let activityViewController = UIActivityViewController(activityItems: [shareImage], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = collectionView
        activityViewController.popoverPresentationController?.sourceRect = CGRect(origin: point, size: .zero)
        present(activityViewController, animated: true, completion: nil)
    }
    
    private func copyAction(index: Int) {
        guard index <= drawings.endIndex else { return }
        drawings.append(drawings[index])
        let indexPath = IndexPath(row: collectionView.numberOfItems(inSection: 0), section: 0)
        collectionView.insertItems(at: [indexPath])
    }
    
    private func deleteAction(index: Int) {
        guard index < drawings.endIndex else { return }
        drawings.remove(at: index)
        collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        guard index != drawings.endIndex else { return } // 削除した要素が配列の末尾だった場合はリロード不要
        let indexPaths = (index ..< drawings.endIndex).map {
            return IndexPath(row: $0, section: 0)
        }
        collectionView.reloadItems(at: indexPaths)
    }
}
