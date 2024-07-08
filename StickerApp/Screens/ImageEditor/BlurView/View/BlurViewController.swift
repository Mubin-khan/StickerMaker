//
//  BlurViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/8/24.
//

import UIKit

class BlurViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var imageViewHeightCon: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthCon: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    
    let fullImage : UIImage
    var blurImage : UIImage?
    var blurImageLayer : CALayer?
    var blurImageLayerMaskLayer : CAShapeLayer?
    var initialSize : CGSize = .zero
    
    
    init(fullImage: UIImage) {
        self.fullImage = fullImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initialSize = fullImage.size.calculateFinalSize(in: CGSize(width: containerView.bounds.size.width, height: containerView.bounds.size.height - 100))
        imageViewHeightCon.constant = initialSize.height
        imageViewWidthCon.constant = initialSize.width
        
        topImageView.image = fullImage
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1){
            self.readyBlurTool()
        }
        
        addPanGestureToView(View: topImageView)
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
    var bazierPaths: [ERBlurPath] = []
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: topImageView)

        if gesture.state == .began {
            let updatedLineWidth = lineWidth //(lineWidth / contentScrollView.zoomScale) / currentScale
            let path = ERBlurPath(pathWidth: updatedLineWidth, ratio: 1, startPoint: point, blendMode: blendMode)
            blurImageLayerMaskLayer?.lineWidth = updatedLineWidth
            blurImageLayerMaskLayer?.path = path.path.cgPath
            bazierPaths.append(path)
            lastGesturePoint = point
        }
        
        else if gesture.state == .changed {
            guard let path = bazierPaths.last else {return}
            let lastPoint = path.linePoints.last
            path.addLine(to: point, from: lastPoint)
            blurImageLayerMaskLayer?.path = path.path.cgPath
            
//            let newPath = ERPath(pathWidth: path.pathWidth, ratio: path.ratio, startPoint: lastGesturePoint, blendMode: blendMode)
//            
//            let count = path.linePoints.count
//            if count > 2 {
//                let first = path.linePoints[count - 3]
//                let second = path.linePoints[count - 2]
//                let third = path.linePoints[count - 1]
//                
//                // Get two mid points. Mid points are just the average of the two points
//                let firstMid = CGPoint(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2)
//                let secondMid = CGPoint(x: (third.x + second.x) / 2, y: (third.y + second.y) / 2)
//                
//                newPath.path.move(to: firstMid)
//                newPath.path.addQuadCurve(to: secondMid, controlPoint: second)
//                blurImageLayerMaskLayer?.path = newPath.path.cgPath
////                redrawPath(path: newPath, blendMode: path.blendMode, lineWidth: path.pathWidth)
//            }
//            else {
//                newPath.path.move(to: lastGesturePoint)
//                newPath.path.addQuadCurve(to: point, controlPoint: lastGesturePoint)
//                blurImageLayerMaskLayer?.path = newPath.path.cgPath
////                redrawPath(path: newPath, blendMode: path.blendMode, lineWidth: path.pathWidth)
//            }
            
            lastGesturePoint = point
//            print(lastGesturePoint)
        }
        else if gesture.state == .ended || gesture.state == .cancelled{
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
            generateNewMosaicImage()
        }
    }
    
    /// 传入inputImage 和 inputMosaicImage则代表仅想要获取新生成的mosaic图片
    @discardableResult
    func generateNewMosaicImage(inputImage: UIImage? = nil, inputMosaicImage: UIImage? = nil) -> UIImage? {
        let renderRect = CGRect(origin: .zero, size: fullImage.size)
        
        UIGraphicsBeginImageContextWithOptions(fullImage.size, false, fullImage.scale)
//        if inputImage != nil {
//            inputImage?.draw(in: renderRect)
//        } else {
            var drawImage: UIImage?
//            if tools.contains(.filter), let image = filterImages[currentFilter.name] {
//                drawImage = image
//            } else {
                drawImage = fullImage
//            }

            drawImage?.draw(at: .zero)
//            if tools.contains(.adjust), brightness != 0 || contrast != 0 || saturation != 0 {
//                drawImage = drawImage?.zl.adjust(brightness: brightness, contrast: contrast, saturation: saturation)
//            }

            drawImage?.draw(in: renderRect)
//        }
        
        let context = UIGraphicsGetCurrentContext()
        bazierPaths.forEach { path in
            var startPointX = path.startPoint.x / (imageViewWidthCon.constant / fullImage.size.width)
            var startPointY = path.startPoint.y / (imageViewHeightCon.constant / fullImage.size.height)
            context?.move(to: CGPoint(x: startPointX, y: startPointY))
            path.linePoints.forEach { point in
                var pointX = point.x / (imageViewWidthCon.constant / fullImage.size.width)
                var pointY = point.y / (imageViewHeightCon.constant / fullImage.size.height)
                context?.addLine(to: CGPoint(x: pointX, y: pointY))
            }
            context?.setLineWidth(path.path.lineWidth / (imageViewWidthCon.constant / fullImage.size.width))
            context?.setLineCap(.round)
            context?.setLineJoin(.round)
            context?.setBlendMode(.clear)
            context?.strokePath()
        }
        
        var midImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let midCgImage = midImage?.cgImage else {
            return nil
        }
        
        midImage = UIImage(cgImage: midCgImage, scale: fullImage.scale, orientation: .up)
        
        UIGraphicsBeginImageContextWithOptions(fullImage.size, false, fullImage.scale)
        // 由于生成的mosaic图片可能在边缘区域出现空白部分，导致合成后会有黑边，所以在最下面先画一张原图
        fullImage.draw(in: renderRect)
        (inputMosaicImage ?? blurImage)?.draw(in: renderRect)
        midImage?.draw(at: .zero)
        
        let temp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgi = temp?.cgImage else {
            return nil
        }
        let image = UIImage(cgImage: cgi, scale: fullImage.scale, orientation: .up)
        
        if inputImage != nil {
            return image
        }
        
//        editImage = image
        topImageView.image = image
        blurImageLayerMaskLayer?.path = nil
        
        return image
    }

   
    func readyBlurTool(){
        blurImage = fullImage.blurImage()
        
        blurImageLayer = CALayer()
        blurImageLayer?.contents = blurImage?.cgImage
        topImageView.layer.addSublayer(blurImageLayer!)
        
        blurImageLayerMaskLayer = CAShapeLayer()
        blurImageLayerMaskLayer?.strokeColor = UIColor.blue.cgColor
        blurImageLayerMaskLayer?.fillColor = nil
        blurImageLayerMaskLayer?.lineCap = .round
        blurImageLayerMaskLayer?.lineJoin = .round
        topImageView.layer.addSublayer(blurImageLayerMaskLayer!)
        
        blurImageLayer?.frame = topImageView.bounds
        blurImageLayerMaskLayer?.frame = topImageView.bounds
        blurImageLayer?.mask = blurImageLayerMaskLayer
    }
    
    @IBAction func blurAction(_ sender: Any) {
        blurImage = fullImage.blurImage()
//        blurImageLayer?.contents = blurImage?.cgImage
    }
    
    @IBAction func clearAction(_ sender: Any) {
//        blurImage =
//        blurImageLayer?.contents = blurImage?.cgImage
    }
    
    
    @IBAction func doneAction(_ sender: Any) {
        let img = imageContainerView.toImage()
        let vc = ImageEditViewController(image: img)
        navigationController?.pushViewController(vc, animated: true)
    }
}
