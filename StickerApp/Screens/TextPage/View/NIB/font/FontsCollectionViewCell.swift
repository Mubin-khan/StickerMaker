//
//  FontsCollectionViewCell.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/24/24.
//

import UIKit

class FontsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var fontContainerview: UIView!
    @IBOutlet weak var fontLabel: UILabel!
    static let fontsIdentifier = "FontsCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        fontContainerview.layer.cornerRadius = fontContainerview.bounds.height / 2
        fontContainerview.layer.borderWidth = 1.5
        fontContainerview.layer.borderColor = UIColor.white.cgColor
    }

    func setUp(str : String){
        fontLabel.font = UIFont(name: str, size: 15)
        fontLabel.text = str
    }
}
