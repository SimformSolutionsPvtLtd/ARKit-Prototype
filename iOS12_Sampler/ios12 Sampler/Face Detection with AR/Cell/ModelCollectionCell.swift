//
//  ModelCollectionCell.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 01/05/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import UIKit

class ModelCollectionCell: UICollectionViewCell {

    var modelImgs: [String] = ["Neon", "Heart", "Star", "Swag", "Glasses", "Robo", "Cyclops"]

    @IBOutlet weak var modelImgVw: UIImageView!

    func configureCell(indexPath: Int) {
        modelImgVw.image = UIImage(named: modelImgs[indexPath])
        modelImgVw.layer.cornerRadius = (modelImgVw.layer.frame.width / 2)
    }
}
