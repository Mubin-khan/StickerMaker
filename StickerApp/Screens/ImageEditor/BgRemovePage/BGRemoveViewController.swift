//
//  BGRemoveViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/5/24.
//

import UIKit

class BGRemoveViewController: UIViewController, UIGestureRecognizerDelegate {
    
    enum EditState {
        case erase
        case restore
    }

    @IBOutlet weak var maskingView: UIView!
    @IBOutlet weak var ContainerView: UIView!
    @IBOutlet weak var contentviewHeightCon: NSLayoutConstraint!
    @IBOutlet weak var contentviewWidthCon: NSLayoutConstraint!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var sliderViewBottomCon: NSLayoutConstraint!
    
    var fullImage : UIImage
    var maskImage : UIImage?
    var sampleMaskImage : UIImage?
    
    let maskLayer = CALayer()
    var maskShapeLayer = CAShapeLayer()
    private var renderer: UIGraphicsImageRenderer?
    var initialSize : CGSize = .zero
    var selectedState : EditState = .erase {
        didSet {
            if selectedState == .erase {
                blendMode = .clear
            }else {
                blendMode = .normal
            }
        }
    }
    
    init(fullImage: UIImage, maskImage: UIImage? = nil) {
        self.fullImage = fullImage
        self.maskImage = maskImage
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initialSize = fullImage.size.calculateFinalSize(in: ContainerView.bounds.size)
        contentviewHeightCon.constant = initialSize.height
        contentviewWidthCon.constant = initialSize.width
        
        topImageView.image = fullImage
        topImageView.layer.mask = maskLayer
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            self.updateBounds()
        }
        
        addPanGestureToView(View: ContainerView)
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
        maskLayer.contents = image.cgImage
        sampleMaskImage = image
        
//        let imageName = UUID().uuidString
//        DocDirectoryHelper.shared.saveImageToDoc(imgName: imageName, image: sampleMaskImage)
//        
//        self.object = EverythingTogether(
//            adjustVariable: AdjustFilterManager.shared.getCurrentAdjustModel(),
//            filterVariable: FilterModel(selectedCategory: selectedFilterCategory, selectedContent: selectedFilterContent, filter: currentFilter), bgVariable: BackgroundModel(bgImage: UIImage(named: "sample")),
//            cropVariable: ERCropModel(cropRect : currentCropRect, scale: 1, translation: CGPoint(x: 0, y: 0)), eraseRestoreImageModel: EraseRestoreImageModel(imageName: imageName)
//        )
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
    var blendMode : CGBlendMode = .clear
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
            maskShapeLayer.path = path.path.cgPath
            
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
    }

    @IBAction func sliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        lineWidth = CGFloat(sender.value * 60)
    }
    
    @IBAction func eraseAction(_ sender: Any) {
        selectedState = .erase
    }
    
    @IBAction func restoreAction(_ sender: Any) {
        selectedState = .restore
    }
    
    @IBAction func backAction(_ sender: Any) {
        
    }
    
    @IBAction func doneAction(_ sender: Any) {
        let img = maskingView.toImage()
        let nonTransparentOnly = img.cropNonTransparent() ?? img
        let vc = ImageEditViewController(image: nonTransparentOnly)
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
 
