//
//  ShapeCropViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/6/24.
//

import UIKit

class ShapeCropViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageYanchorCon: NSLayoutConstraint!
    @IBOutlet weak var imageXanchorCon: NSLayoutConstraint!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var maskingView: UIView!
    
    let fullImage : UIImage
    var maskLayer = CALayer()
    var maskImage = UIImage(named: "loveShape")
    var finalMaskImage : UIImage?
    private var renderer: UIGraphicsImageRenderer?
    
    init(fullImage: UIImage) {
        self.fullImage = fullImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        topImageView.image = fullImage
        maskingView.layer.mask = maskLayer
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            self.updateBounds()
        }
        
        addPanGestureToView(View: maskingView)
        addPinchGestureToView(View: maskingView)
        addRotationGestureToView(View: maskingView)
    }

    override func viewDidLayoutSubviews() {
        maskLayer.frame = maskingView.bounds
    }

    private func updateBounds(){
        renderer = UIGraphicsImageRenderer(size: maskingView.bounds.size)
        maskLayer.frame = maskingView.bounds
        installSampleMask()
    }
    
    private func installSampleMask() {
        
        guard let renderer = renderer else { return }
        let image = renderer.image { (context) in
            // Draw the base image
            fullImage.draw(in: maskingView.bounds)
            
            // Set the blend mode to normal and draw the mask image
            context.cgContext.setBlendMode(.clear)
            maskImage?.draw(in: maskingView.bounds, blendMode: .clear, alpha: 1.0)
            
            // Save the current graphics state
            context.cgContext.saveGState()
            
            // Apply a horizontal flip transformation
            context.cgContext.translateBy(x: 0, y: maskingView.bounds.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            // Create a new image from the mask image where the alpha is used as the mask
            if let maskCGImage = maskImage?.convertUIImageToCGImage() {
                let mask = CGImage(maskWidth: maskCGImage.width,
                                   height: maskCGImage.height,
                                   bitsPerComponent: maskCGImage.bitsPerComponent,
                                   bitsPerPixel: maskCGImage.bitsPerPixel,
                                   bytesPerRow: maskCGImage.bytesPerRow,
                                   provider: maskCGImage.dataProvider!,
                                   decode: nil,
                                   shouldInterpolate: true)
                
                context.cgContext.clip(to: maskingView.bounds, mask: mask!)
                context.cgContext.setBlendMode(.normal)
                context.cgContext.fill(maskingView.bounds)
            }
        }
        maskLayer.contents = image.cgImage
        
        let image1 = renderer.image { (context) in
            // Draw the base image
            fullImage.draw(in: maskingView.bounds)
            
            // Set the blend mode to normal and draw the mask image
            context.cgContext.setBlendMode(.normal)
            maskImage?.draw(in: maskingView.bounds, blendMode: .normal, alpha: 1.0)
            
            // Save the current graphics state
            context.cgContext.saveGState()
            
            // Apply a horizontal flip transformation
            context.cgContext.translateBy(x: 0, y: maskingView.bounds.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            // Create a new image from the mask image where the alpha is used as the mask
            if let maskCGImage = maskImage?.convertUIImageToCGImage() {
                let mask = CGImage(maskWidth: maskCGImage.width,
                                   height: maskCGImage.height,
                                   bitsPerComponent: maskCGImage.bitsPerComponent,
                                   bitsPerPixel: maskCGImage.bitsPerPixel,
                                   bytesPerRow: maskCGImage.bytesPerRow,
                                   provider: maskCGImage.dataProvider!,
                                   decode: nil,
                                   shouldInterpolate: true)
                
                context.cgContext.clip(to: maskingView.bounds, mask: mask!)
                context.cgContext.setBlendMode(.clear)
                context.cgContext.fill(maskingView.bounds)
            }
        }
        finalMaskImage = image1
    }
    
    var panGesture : UIPanGestureRecognizer?
    var pinchGesture : UIPinchGestureRecognizer?
    var rotateGesture : UIRotationGestureRecognizer?
    
    func addPanGestureToView(View vw : UIView){
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        
        vw.isUserInteractionEnabled = true
        panGesture?.delegate = self
        if let panGesture {
            vw.addGestureRecognizer(panGesture)
        }
    }
    
    
    func addPinchGestureToView(View vw : UIView){
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        
        vw.isUserInteractionEnabled = true
        pinchGesture?.delegate = self
        if let pinchGesture {
            vw.addGestureRecognizer(pinchGesture)
        }
    }
    
    func addRotationGestureToView(View vw : UIView){
        rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        
        vw.isUserInteractionEnabled = true
        rotateGesture?.delegate = self
        if let rotateGesture {
            vw.addGestureRecognizer(rotateGesture)
        }
    }
    
    var lastpanPoint : CGPoint = .zero
    var begginingCenter : CGPoint = .zero
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: maskingView)
        if gesture.state == .began {
            lastpanPoint = point
            begginingCenter = CGPoint(x: imageXanchorCon.constant, y: imageYanchorCon.constant)
//            pinchGesture?.isEnabled = false
        }else if gesture.state == .changed {
            imageXanchorCon.constant = begginingCenter.x + (point.x - lastpanPoint.x)
            imageYanchorCon.constant = begginingCenter.y + (point.y - lastpanPoint.y)
        }
        
        else if gesture.state == .ended {
//            pinchGesture?.isEnabled = true
        }
    }
    
    let minScale : CGFloat = 0.5
    let maxScale : CGFloat = 4

    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        let currentScale = self.topImageView.frame.width/self.topImageView.bounds.size.width
        var newScale = gesture.scale
        if currentScale * gesture.scale < minScale {
            newScale = minScale / currentScale
        } else if currentScale * gesture.scale > maxScale {
            newScale = maxScale / currentScale
        }
        
        topImageView.transform = topImageView.transform.scaledBy(x: newScale, y: newScale)
        gesture.scale = 1
    }
    
    @objc func handleRotationGesture(_ gesture: UIRotationGestureRecognizer) {
        topImageView.transform = topImageView.transform.rotated(by: gesture.rotation)
        gesture.rotation = 0
    }
    
    
    @IBAction func doneAction(_ sender: Any) {
        let baseImage = containerView.toImage()
        guard let cgImage = baseImage.cgImage, let cgMask = finalMaskImage!.cgImage else {
            return
        }
        UIGraphicsBeginImageContext(baseImage.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        // Save the current graphics state
        context.saveGState()
        
        // Apply a horizontal flip transformation
        context.translateBy(x: 0, y: baseImage.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let rect = CGRect(x: 0, y: 0, width: baseImage.size.width, height: baseImage.size.height)
        context.clip(to: rect, mask: cgMask)
        context.draw(cgImage, in: rect)
        let img = UIImage(cgImage: context.makeImage()!)
        let croppedImg = img.cropNonTransparent() ?? img
        

        let vc = ImageEditViewController(image: croppedImg)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func closeAction(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension ShapeCropViewController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
