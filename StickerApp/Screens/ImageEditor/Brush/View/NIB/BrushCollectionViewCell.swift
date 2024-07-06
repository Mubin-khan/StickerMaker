//
//  BrushCollectionViewCell.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/6/24.
//

import UIKit

class BrushCollectionViewCell: UICollectionViewCell {

    static let brushIdentifier = "BrushCollectionViewCell"
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setup(to str : String){
        contentImageView.image = UIImage(named: str.lowercased())
        titleLabel.text = str.capitalized
    }

}
