//
//  BlurViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/8/24.
//

import UIKit

class BlurViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // undo redo
    var undoMng = UndoManager()
    var object : Any = "none"

    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var maskingView: UIView!
    @IBOutlet weak var blurImageView: UIImageView!
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var imageViewHeightCon: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthCon: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    
    var isBlur : Bool = true
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
        
        contentScrollView.delegate = self
        contentScrollView.minimumZoomScale = 1
        contentScrollView.maximumZoomScale = 4
        
        undoButton.isEnabled = false
        redoButton.isEnabled = false
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
            let updatedLineWidth = lineWidth / contentScrollView.zoomScale
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
        else if gesture.state == .ended || gesture.state == .cancelled, let mask = maskImage {
           saveImageforUndoRedo(img: mask)
        }
    }
    
    private func saveImageforUndoRedo(img : UIImage) {
        let imageName = UUID().uuidString
        let isSaved = ImageSaveRetrieveManager.shared.saveImageToDocumentsFolder(image: img, imageName: imageName)
        
        let obj = BlurUndoRedoModel(isBlur: isBlur, imageName: imageName)
        setObject(obj)
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
        
        let imageName = UUID().uuidString
        let isSaved = ImageSaveRetrieveManager.shared.saveImageToDocumentsFolder(image: image, imageName: imageName)
        
        self.object = BlurUndoRedoModel(isBlur: isBlur, imageName: imageName)
        enableDisableUIControl()
    }
    
    @IBAction func blurAction(_ sender: Any) {
        isBlur = true
        blendMode = .normal
        blurImageView.image = blurImage
        
        if let obj = object as? BlurUndoRedoModel {
            let newObj = BlurUndoRedoModel(isBlur: isBlur, imageName: obj.imageName)
            if obj != newObj {
                setObject(newObj)
            }
        }
    }
    
    @IBAction func clearAction(_ sender: Any) {
        blendMode = .clear
    }
    
    @IBAction func pixelateAction(_ sender: Any) {
        isBlur = false
        blendMode = .normal
        blurImageView.image = pixelate
        
        if let obj = object as? BlurUndoRedoModel {
            let newObj = BlurUndoRedoModel(isBlur: isBlur, imageName: obj.imageName)
            if obj != newObj {
                setObject(newObj)
            }
        }
    }
    
    @IBAction func doneAction(_ sender: Any) {
        let img = imageContainerView.toImage()
        let vc = ImageEditViewController(image: img)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backAction(_ sender: Any) {
//        dismiss(animated: true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        lineWidth = CGFloat(sender.value * 60)
    }
    
    @IBAction func undoButtonAction(_ sender: Any) {
        if self.undoMng.canUndo {
            self.undoMng.undo()
        }
        self.enableDisableUIControl()
    }
    
    @IBAction func redoButtonAction(_ sender: Any) {
        if self.undoMng.canRedo {
            self.undoMng.redo()
        }
        self.enableDisableUIControl()
    }

}

extension BlurViewController : UIScrollViewDelegate {
    // UIScrollViewDelegate method to return the view for zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
}


extension BlurViewController {
    @objc func setObject(_ newObject: Any) {
        
        let oldObject = object
        object = newObject
        
        // 1. First way to register Undo
        self.undoMng.registerUndo(withTarget: self, selector:
                                    #selector(self.setObject(_:)), object: oldObject)
        
        if undoMng.isUndoing || undoMng.isRedoing {
            if let obj1 = object as? BlurUndoRedoModel, let obj2 = oldObject as? BlurUndoRedoModel {
                if obj1 != obj2 {
                    setMaskImageFromUndoRedo(obj: obj1)
                }
            }
        }
        
        self.enableDisableUIControl()
    }
    
    func enableDisableUIControl(){
        undoButton.isEnabled = undoMng.canUndo
        redoButton.isEnabled = undoMng.canRedo
//        if undoMng.canUndo {
//            undoIconImageView.setImageColor(color: .white)
//        }else {
//            undoIconImageView.setImageColor(color: .gray)
//        }
//
//        if undoMng.canRedo {
//            redoIconImageView.setImageColor(color: .white)
//        }else {
//            redoIconImageView.setImageColor(color: .gray)
//        }
    }
    
    func setMaskImageFromUndoRedo(obj : BlurUndoRedoModel){
        let img = ImageSaveRetrieveManager.shared.retrieveImageFromDocumentsFolder(imageName: obj.imageName)
        maskLayer.contents = img?.cgImage
        
        if obj.isBlur {
            isBlur = true
            blurImageView.image = blurImage
        }else {
            isBlur = false
            blurImageView.image = pixelate
        }
    }
}
