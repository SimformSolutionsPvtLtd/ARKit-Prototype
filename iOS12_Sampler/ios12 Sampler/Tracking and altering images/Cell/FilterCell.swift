//
//  FilterCell.swift
//  ios12 Sampler
//
//  Created by Dhruvil Vora on 05/01/24.
//  Copyright © 2024 Testing. All rights reserved.
//

import UIKit

protocol FilterCellTapDelegate: AnyObject {
    func filterCellTapped(index: Int)
}

class FilterCell: UICollectionViewCell {
    @IBOutlet weak var imgFilter: UIImageView!
    @IBOutlet weak var lblFilterName: UILabel!
    @IBOutlet weak var dimVw: UIView!
    @IBOutlet weak var imgTick: UIImageView!
    
    weak var filterCellTapDelegate: FilterCellTapDelegate?
    var tappedIndex: Int = 0

    func configureUI(filterModel: FilterModel, index: Int) {
        tappedIndex = index
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onFilterCellTap))
        contentView.addGestureRecognizer(tapGesture)
        imgFilter.image = filterModel.filterDummyImage
        lblFilterName.text = filterModel.filterName
        dimVw.isHidden = !filterModel.isSelected
    }

    @objc func onFilterCellTap() {
        dimVw.isHidden = false
        filterCellTapDelegate?.filterCellTapped(index: tappedIndex)
    }
}
