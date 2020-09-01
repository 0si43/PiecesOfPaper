//
//  ThumbnailCollectionViewCell.swift
//  LikeAPaper
//
//  Created by nakajima on 2020/05/02.
//  Copyright © 2020 Tsuyoshi nakajima. All rights reserved.
//

import UIKit

class ThumbnailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    /// Set up the view initially.
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.shadowPath = UIBezierPath(rect: imageView.bounds).cgPath
        imageView.layer.shadowOpacity = 0.3
        imageView.layer.shadowOffset = CGSize(width: 0, height: 3)
        imageView.clipsToBounds = false
    }
}

