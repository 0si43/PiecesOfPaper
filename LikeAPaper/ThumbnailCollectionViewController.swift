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

    var dataModel = DataModel()
    var selectedDrawing: PKDrawing?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performSegue(withIdentifier: "toCanvasView", sender: self)
    }

    @IBAction func newCanvas(_ sender: Any) {
        performSegue(withIdentifier: "toCanvasView", sender: self)
    }
    
    @IBAction func update(_ sender: Any) {
        collectionView!.reloadData()
    }
    
    @IBAction func daleteData(_ sender: Any) {
        dataModel.drawings.removeLast()
        collectionView!.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController,
            let canvas = navigationController.topViewController as? CanvasViewController {
            canvas.drawing = selectedDrawing
        }
        selectedDrawing = nil
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataModel.drawings.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ThumbnailCollectionViewCell else { fatalError("Unexpected cell type.") }
        let drawing = dataModel.drawings[indexPath.row].image(from: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), scale: 1.0)
        cell.imageView.image = drawing
        return cell
    }
    

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedDrawing = dataModel.drawings[indexPath.row]
        performSegue(withIdentifier: "toCanvasView", sender: self)
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
