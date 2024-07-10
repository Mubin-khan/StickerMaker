//
//  BrushViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/6/24.
//

import UIKit
import CoreImage

class BrushViewController: UIViewController, UIGestureRecognizerDelegate {

    enum EditState : String, CaseIterable {
        case erase = "Erase"
        case restore = "Restore"
        case invert = "Invert"
        case reset = "Reset"
    }
    
    @IBOutlet weak var imageViewHeightCon: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthCon: NSLayoutConstraint!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var maskingView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var fetureCollectionView: UICollectionView!
    
    var fullImage : UIImage
    var maskImage : UIImage?
    let maskLayer = CALayer()
    var maskShapeLayer = CAShapeLayer()
    private var renderer: UIGraphicsImageRenderer?
    var initialSize : CGSize = .zero
    
    init(fullImage: UIImage) {
        self.fullImage = fullImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var selectedState : EditState = .erase {
        didSet {
            if selectedState == .erase {
                blendMode = .clear
            }else {
                blendMode = .normal
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        maskImage = createBlackImage(size: fullImage.size)
        
        initialSize = fullImage.size.calculateFinalSize(in: CGSize(width: containerView.bounds.size.width, height: containerView.bounds.size.height - 100))
        imageViewHeightCon.constant = initialSize.height
        imageViewWidthCon.constant = initialSize.width
        
        topImageView.image = fullImage
        topImageView.layer.mask = maskLayer
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            self.updateBounds()
        }
        
        addPanGestureToView(View: containerView)
        
        let nib = UINib(nibName: BrushCollectionViewCell.brushIdentifier, bundle: nil)
        fetureCollectionView.register(nib, forCellWithReuseIdentifier: BrushCollectionViewCell.brushIdentifier)
        fetureCollectionView.delegate = self
        fetureCollectionView.dataSource = self
    }
    
    func createBlackImage(size: CGSize) -> UIImage? {
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


    override func viewDidLayoutSubviews() {
        maskLayer.frame = maskingView.bounds
    }

    private func updateBounds(){
        renderer = UIGraphicsImageRenderer(size: maskingView.bounds.size)
        maskLayer.frame = maskingView.bounds
        installSampleMask()
    }
    
//    private func installSampleMask() {
//        
//        guard let renderer = renderer else { return }
//        let image = renderer.image { (context) in
//            fullImage.draw(in: maskingView.bounds)
//        }
//        maskLayer.contents = image.cgImage
//    }
    
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
        maskImage = image
    }
    
    // Function to invert a mask image
    func invertMaskImage(maskImg : UIImage) -> UIImage? {
       let output = maskImg.invertAlpha()
        maskImage = output
        return output
    }
    
   
    @IBAction func sliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        lineWidth = CGFloat(sender.value * 60)
    }
    
    @IBAction func closeAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        let img = maskingView.toImage()
        let nonTransparentOnly = img.cropNonTransparent() ?? img
        let vc = ImageEditViewController(image: nonTransparentOnly)
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension BrushViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        EditState.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BrushCollectionViewCell.brushIdentifier, for: indexPath) as? BrushCollectionViewCell {
            
            cell.setup(to: EditState.allCases[indexPath.row].rawValue)
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 80, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch EditState.allCases[indexPath.row] {
        case .erase : selectedState = .erase
        case .restore : selectedState = .restore
        case .invert :
            if let mask = maskImage {
                maskLayer.contents = invertMaskImage(maskImg: mask)?.cgImage
            }
        case .reset : installSampleMask()
        }
    }
}
