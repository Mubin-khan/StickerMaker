//
//  GifCollectionViewCell.swift
//  SampleTenor
//
//  Created by DSDEVMAC2 on 6/27/24.
//

import UIKit
import Kingfisher

class GifCollectionViewCell: UICollectionViewCell {
    
    static let gifcellIdentifier = "GifCollectionViewCell"

    @IBOutlet weak var gifImageView: AnimatedImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setup(url : URL){
        gifImageView.kf.setImage(with: url)
    }
}
