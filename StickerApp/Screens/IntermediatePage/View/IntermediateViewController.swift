//
//  IntermediateViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/20/24.
//

import UIKit

class IntermediateViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    private var cornerpoints =  [CornerpointView]()
    
    private var imageCropper: ARImageCropper!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true
        // Initialize the ARImageCropper instance
        imageCropper = ARImageCropper(frame: .zero)
        imageCropper.backgroundColor = .clear
        
        // Set the properties for the image cropper
        imageCropper.image = UIImage(named: "image1")
        imageCropper.croppedImageSize = CGSize(width: 100, height: 100) // Set the desired cropped image size
        imageCropper.borderColor = .black // Customize the border color
        imageCropper.borderWidth = 2.0 // Customize the border width
        imageCropper.cornersColor = .green // Customize the corners color
        imageCropper.cornersSize = CGSize(width: 20, height: 20) // Customize the corners size
        imageCropper.cornersLineWidth = 3 // Customize the corners line width
        imageCropper.cornerShape = .square // Customize the corner shape
        
        // Add the image cropper to the view hierarchy
        view.addSubview(imageCropper)
        
        // Set the frame or constraints for the image cropper
        imageCropper.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageCropper.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            imageCropper.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            imageCropper.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            imageCropper.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0) // Maintain aspect ratio
        ])
    }
    
    

}
