//
//  ImageEditViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/30/24.
//

import UIKit

class ImageEditViewController: UIViewController {

    @IBOutlet weak var sampleImageView: UIImageView!
    var selectedFilter : SMFilter = SMFilter.ciFilters[10]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func buttonAction(_ sender: Any) {
        if let img = UIImage(named: "image4") {
            sampleImageView.image = selectedFilter.applier?(img)
        }
    }
    

}
