//
//  BlurViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/8/24.
//

import UIKit

class BlurViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var maskingView: UIView!
    @IBOutlet weak var blurImageView: UIImageView!
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var imageViewHeightCon: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthCon: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    
    let fullImage : UIImage
    var blurImage : UIImage?
    var pixelate : UIImage?
    var blurImageLayer : CALayer?
    var blurImageLayerMaskLayer : CAShapeLayer?
    var initialSize : CGSize = .zero
    
    let maskLayer = CALayer()
    private var renderer: UIGraphicsImageRenderer?
    var maskImage : UIImage?
    
    init(fullImage: UIImage) {
        self.fullImage = fullImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let mask = createAlphaMask(size: fullImage.size) {
            maskImage = UIImage(cgImage: mask)
        }
        
        blurImage = fullImage.blurImage()
        pixelate = fullImage.pixelateImage()
        
        blurImageView.image = blurImage
        
        initialSize = fullImage.size.calculateFinalSize(in: CGSize(width: containerView.bounds.size.width, height: containerView.bounds.size.height - 100))
        imageViewHeightCon.constant = initialSize.height
        imageViewWidthCon.constant = initialSize.width
        
        topImageView.image = fullImage
        maskingView.layer.mask = maskLayer
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1){
            self.readyBlurTool()
        }
        
        addPanGestureToView(View: containerView)
    }
    
    func createClearMaskImage(size: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // Use a scale factor of 1 for pixel-perfect rendering
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        let image = renderer.image { context in
            // Set the fill color to black
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        return image
    }
    
    func createAlphaMask(size: CGSize) -> CGImage? {
        let bitsPerComponent: Int = 8
        let bytesPerPixel: Int = 1
        let bytesPerRow: Int = bytesPerPixel * Int(size.width)
        let totalBytes = bytesPerRow * Int(size.height)
        
        var alphaData = [UInt8](repeating: 255, count: totalBytes)
        
//        for y in 0..<Int(size.height) {
//            for x in 0..<Int(size.width) {
//                let distanceFromCenter = hypot(CGFloat(x) - size.width / 2, CGFloat(y) - size.height / 2)
//                let maxDistance = hypot(size.width / 2, size.height / 2)
//                let alpha = UInt8((1.0 - min(distanceFromCenter / maxDistance, 1.0)) * 255.0)
//                alphaData[y * bytesPerRow + x] = alpha
//                print(alpha, distanceFromCenter)
//            }
//        }
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let dataProvider = CGDataProvider(data: NSData(bytes: &alphaData, length: totalBytes))!
        let maskImage = CGImage(width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: bitsPerComponent,
                                bitsPerPixel: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo,
                                provider: dataProvider,
                                decode: nil,
                                shouldInterpolate: false,
                                intent: .defaultIntent)
        return maskImage
    }
    
    var panGesture : UIPanGestureRecognizer?
    func addPanGestureToView(View vw : UIView){
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        
        vw.isUserInteractionEnabled = true
        panGesture?.delegate = self
        if let panGesture {
            vw.addGestureRecognizer(panGesture)
        }
    }
    
    var lastGesturePoint : CGPoint = .zero
    var lineWidth : CGFloat = 30
    var blendMode : CGBlendMode = .normal
    var bazierPaths: [ERPath] = []
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: maskingView)

        if gesture.state == .began {
            let updatedLineWidth = lineWidth //(lineWidth / contentScrollView.zoomScale) / currentScale
            let path = ERPath(pathWidth: updatedLineWidth, ratio: 1, startPoint: point, blendMode: blendMode)
            bazierPaths.append(path)
            lastGesturePoint = point
        }
        
        else if gesture.state == .changed {
            guard let path = bazierPaths.last else {return}
            let lastPoint = path.linePoints.last
            path.addLine(to: point, from: lastPoint)
            
            let newPath = ERPath(pathWidth: path.pathWidth, ratio: path.ratio, startPoint: lastGesturePoint, blendMode: blendMode)
            
            let count = path.linePoints.count
            if count > 2 {
                let first = path.linePoints[count - 3]
                let second = path.linePoints[count - 2]
                let third = path.linePoints[count - 1]
                
                // Get two mid points. Mid points are just the average of the two points
                let firstMid = CGPoint(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2)
                let secondMid = CGPoint(x: (third.x + second.x) / 2, y: (third.y + second.y) / 2)
                
                newPath.path.move(to: firstMid)
                newPath.path.addQuadCurve(to: secondMid, controlPoint: second)
                
                redrawPath(path: newPath, blendMode: path.blendMode, lineWidth: path.pathWidth)
            }
            else {
                newPath.path.move(to: lastGesturePoint)
                newPath.path.addQuadCurve(to: point, controlPoint: lastGesturePoint)
                redrawPath(path: newPath, blendMode: path.blendMode, lineWidth: path.pathWidth)
            }
            
            lastGesturePoint = point
//            print(lastGesturePoint)
        }
        else if gesture.state == .ended {
//            let pathImage = maskingView.asImage()
//            let imageName = UUID().uuidString
//            DocDirectoryHelper.shared.saveImageToDoc(imgName: imageName, image: pathImage)
//            let imgObj = EraseRestoreImageModel(imageName: imageName)
//            if var obj = object as? EverythingTogether {
//                if obj.eraseRestoreImageModel != imgObj {
//                    obj.eraseRestoreImageModel = imgObj
//                    setObject(obj)
//                }
//            }
        }
    }
    
    private func redrawPath(path : ERPath, blendMode : CGBlendMode, lineWidth : CGFloat){
        
        guard let renderer = renderer else { return }
        let image = renderer.image { (context) in
            maskLayer.render(in: context.cgContext)
            context.cgContext.setLineWidth(lineWidth)
            context.cgContext.setLineCap(.round)
            context.cgContext.setLineJoin(.round)
            context.cgContext.setBlendMode(blendMode)
            context.cgContext.addPath(path.path.cgPath)
            context.cgContext.strokePath()
        }
        
        maskLayer.contents = image.cgImage
        maskImage = image
    }
   
    func readyBlurTool(){
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
        maskImage = image
        
//        let imageName = UUID().uuidString
//        DocDirectoryHelper.shared.saveImageToDoc(imgName: imageName, image: sampleMaskImage)
//
//        self.object = EverythingTogether(
//            adjustVariable: AdjustFilterManager.shared.getCurrentAdjustModel(),
//            filterVariable: FilterModel(selectedCategory: selectedFilterCategory, selectedContent: selectedFilterContent, filter: currentFilter), bgVariable: BackgroundModel(bgImage: UIImage(named: "sample")),
//            cropVariable: ERCropModel(cropRect : currentCropRect, scale: 1, translation: CGPoint(x: 0, y: 0)), eraseRestoreImageModel: EraseRestoreImageModel(imageName: imageName)
//        )
    }
    
    @IBAction func blurAction(_ sender: Any) {
        blendMode = .normal
        blurImageView.image = blurImage
    }
    
    @IBAction func clearAction(_ sender: Any) {
        blendMode = .clear
    }
    
    @IBAction func pixelateAction(_ sender: Any) {
        blendMode = .normal
        blurImageView.image = pixelate
    }
    
    @IBAction func doneAction(_ sender: Any) {
        let img = imageContainerView.toImage()
        let vc = ImageEditViewController(image: img)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
}
