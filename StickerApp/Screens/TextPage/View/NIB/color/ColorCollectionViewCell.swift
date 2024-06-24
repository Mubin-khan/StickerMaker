//
//  ColorCollectionViewCell.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/24/24.
//

import UIKit

class ColorCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var myContainer: UIView!
    static let colorsIdentifier = "ColorCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        myContainer.layer.cornerRadius = myContainer.bounds.width / 2
        myContainer.clipsToBounds = true
        myContainer.layer.borderWidth = 1.5
        myContainer.layer.borderColor = UIColor.white.cgColor
    }

}
