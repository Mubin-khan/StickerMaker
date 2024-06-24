//
//  IntermediateViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/20/24.
//

import UIKit
import AVFoundation

class IntermediateViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    private var cornerpoints =  [CornerpointView]()
    var frames : [UIImage] = []
    
    private var imageCropper: ARImageCropper!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true
        initializeCropper(with: UIImage(named: "test")!)
    }
    
    func initializeCropper(with img : UIImage){
        // Initialize the ARImageCropper instance
        imageCropper = ARImageCropper(frame: .zero)
        imageCropper.backgroundColor = .clear
        
        // Set the properties for the image cropper
        imageCropper.image = img
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
    
    func extractFramesFromVideo(at url: URL, frameCount: Int = 10, fromDuration : ) {
        let asset = AVAsset(url: url)
        let assetDuration = CMTimeGetSeconds(asset.duration)
        let times = stride(from: 0, to: assetDuration, by: assetDuration / Double(frameCount - 1)).map {
            CMTimeMakeWithSeconds($0, preferredTimescale: asset.duration.timescale)
        }
        
        extractFrames(at: times, from: asset)
    }
    
    func extractFrames(at times: [CMTime], from asset: AVAsset) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let dispatchGroup = DispatchGroup()

        for time in times {
            dispatchGroup.enter()
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
                if let cgImage = cgImage {
                    let uiImage = UIImage(cgImage: cgImage)
                    self.frames.append(uiImage.normalizeImageOrientation())
                } else if let error = error {
                    print("Error generating image: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
    }
    
    @IBAction func freeStyleAction(_ sender: Any) {
        imageCropper.currentCropStyle = .free
    }
    
    @IBAction func squareStyleAction(_ sender: Any) {
        imageCropper.currentCropStyle = .square
    }
}
