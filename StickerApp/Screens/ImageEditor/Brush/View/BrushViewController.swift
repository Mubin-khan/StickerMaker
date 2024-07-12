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
    
    // undo redo
    var undoMng = UndoManager()
    var object : Any = "none"
    
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var contentScrollView: UIScrollView!
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
        
        initialSize = fullImage.size.calculateFinalSize(in: CGSize(width: containerView.bounds.size.width - 60, height: containerView.bounds.size.height - 100))
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
        
        contentScrollView.delegate = self
        contentScrollView.minimumZoomScale = 1
        contentScrollView.maximumZoomScale = 4
        
        undoButton.isEnabled = false
        redoButton.isEnabled = false
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
        
        self.object = EraseRestoreImageModel(imageName: imageName)
        enableDisableUIControl()
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
            let updatedLineWidth = (lineWidth / contentScrollView.zoomScale)
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
        else if gesture.state == .ended || gesture.state == .cancelled, let mask = maskImage {
           saveImageforUndoRedo(img: mask)
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
        if let msk = output {
            saveImageforUndoRedo(img: msk)
        }
        return output
    }
    
    private func saveImageforUndoRedo(img : UIImage) {
        let imageName = UUID().uuidString
        let isSaved = ImageSaveRetrieveManager.shared.saveImageToDocumentsFolder(image: img, imageName: imageName)
        
        let obj = EraseRestoreImageModel(imageName: imageName)
        setObject(obj)
    }
    
    @IBAction func sliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        lineWidth = CGFloat(sender.value * 60)
    }
    
    @IBAction func closeAction(_ sender: Any) {
//        dismiss(animated: true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        let img = maskingView.toImage()
        let nonTransparentOnly = img.cropNonTransparent() ?? img
        let vc = ImageEditViewController(image: nonTransparentOnly)
        navigationController?.pushViewController(vc, animated: true)
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
        case .reset :
            self.openAlert(title: "Your progress will be lost", message: "Do you want to continue!!", alertStyle: .alert, actionTitles: ["Yes", "No"], actionStyles: [.default, .default], action: [
                { [self] action in
                    undoMng.removeAllActions()
                    installSampleMask()
                },
                { action in
//                    print("Action 2 triggered")
                }
            ])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 35, right: 10)
    }
}


extension BrushViewController : UIScrollViewDelegate {
    // UIScrollViewDelegate method to return the view for zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
}

extension BrushViewController {
    @objc func setObject(_ newObject: Any) {
        
        let oldObject = object
        object = newObject
        
        // 1. First way to register Undo
        self.undoMng.registerUndo(withTarget: self, selector:
                                    #selector(self.setObject(_:)), object: oldObject)
        
        if undoMng.isUndoing || undoMng.isRedoing {
            if let obj1 = object as? EraseRestoreImageModel, let obj2 = oldObject as? EraseRestoreImageModel {
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
    
    func setMaskImageFromUndoRedo(obj : EraseRestoreImageModel){
        let img = ImageSaveRetrieveManager.shared.retrieveImageFromDocumentsFolder(imageName: obj.imageName)
        maskLayer.contents = img?.cgImage
    }
}
