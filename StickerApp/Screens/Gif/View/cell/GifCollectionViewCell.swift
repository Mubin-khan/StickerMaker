//
//  GifCollectionViewCell.swift
//  SampleTenor
//
//  Created by DSDEVMAC2 on 6/27/24.
//

import UIKit
import Kingfisher

class GifCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    static let gifcellIdentifier = "GifCollectionViewCell"

    @IBOutlet weak var gifImageView: AnimatedImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setup(url : URL){
        self.indicator.startAnimating()
        gifImageView.kf.setImage(with: url) { result in
            switch result {
            case .success(_) : self.indicator.stopAnimating()
            default : break
            }
        }
    }
}
