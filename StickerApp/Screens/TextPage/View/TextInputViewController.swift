//
//  TextInputViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/24/24.
//

import UIKit

class TextInputViewController: UIViewController {

    @IBOutlet weak var inputTextContainer: UIView!
    @IBOutlet weak var animateCollectionView: UICollectionView!
    @IBOutlet weak var featureCollectionView: UICollectionView!
    @IBOutlet weak var colorCollectionView: UICollectionView!
    @IBOutlet weak var fontCollectionView: UICollectionView!
    
    var selectedAnimationIndex = 0
    let animatedLabel: CustomTextLabel = {
        let label = CustomTextLabel()
        label.text = "Keyframe Animation"
        label.font = UIFont(name: "Arial Bold", size: 30)
        label.textAlignment = .center
        label.alpha = 1  // Start with the label invisible
        label.textColor = .red
        label.strokeColor = .black
        label.strokeLineWidth = 2
        label.shadowColor = .black
        label.shadowOffset = CGSizeMake(0, 2)
        return label
    }()
    
    let containerview : UIView = {
        let vw = UIView()
        vw.backgroundColor = .clear
        return vw;
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true
        setupAnimateLabel()
        configureCollectionView()
    }
    
    var index = 0
    override func viewWillAppear(_ animated: Bool) {
        frames.removeAll()
        selectedAnimationIndex = index
    }
    
    func setupAnimateLabel(){
        inputTextContainer.addSubview(containerview)
        containerview.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerview.centerXAnchor.constraint(equalTo: inputTextContainer.centerXAnchor),
            containerview.centerYAnchor.constraint(equalTo: inputTextContainer.centerYAnchor),
        ])
        
        containerview.addSubview(animatedLabel)
        containerview.clipsToBounds = true
        animatedLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animatedLabel.leftAnchor.constraint(equalTo: containerview.leftAnchor, constant: 30),
            animatedLabel.rightAnchor.constraint(equalTo: containerview.rightAnchor, constant: -30),
            animatedLabel.topAnchor.constraint(equalTo: containerview.topAnchor, constant: 30),
            animatedLabel.bottomAnchor.constraint(equalTo: containerview.bottomAnchor, constant: -30)
        ])
    }
    
    private func configureCollectionView(){
        let nib = UINib(nibName: ColorCollectionViewCell.colorsIdentifier, bundle: nil)
        colorCollectionView.register(nib, forCellWithReuseIdentifier: ColorCollectionViewCell.colorsIdentifier)
        colorCollectionView.delegate = self
        colorCollectionView.dataSource = self
        
        let nib1 = UINib(nibName: FontsCollectionViewCell.fontsIdentifier, bundle: nil)
        fontCollectionView.register(nib1, forCellWithReuseIdentifier: FontsCollectionViewCell.fontsIdentifier)
        fontCollectionView.delegate = self
        fontCollectionView.dataSource = self
        
        let nib3 = UINib(nibName: AnimCollectionViewCell.animIdentifier, bundle: nil)
        animateCollectionView.register(nib3, forCellWithReuseIdentifier: AnimCollectionViewCell.animIdentifier)
        animateCollectionView.delegate = self
        animateCollectionView.dataSource = self
    }
    
    func animateLabel(animType : availableAnimations){
        UIView.animate(withDuration: 0.0) {
            self.animatedLabel.layer.removeAllAnimations()
        }completion: { [self] _ in
            switch animType {
            case .ZoomIn : zoomInAnimation()
            case .ZoomInOut : zoomInOutAnimation()
            case .RightAndLeft : rightAndLeftAnimation()
            case .leftToRight : leftToRightAnimation()
            case .upAndDown : upAndDownAnimation()
            case .topToBottom : topToBottomAnimation()
            default : break
            }
        }
    }

    func zoomInAnimation(){
        self.animatedLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animateKeyframes(withDuration: 2, delay: 0, options: [], animations: {
            
            // Keyframe 2: Move down and change color to red
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.95) {
                self.animatedLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
            
        }, completion: { [self] _ in
            if selectedAnimationIndex != -1 && availableAnimations.allCases[selectedAnimationIndex] == .ZoomIn {
                self.zoomInAnimation()
            }
        })
    }
    
    func zoomInOutAnimation(){
        UIView.animateKeyframes(withDuration: 2, delay: 0, options: [], animations: {
            self.animatedLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            
            
            // Keyframe 2: Move down and change color to red
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.45) {
                self.animatedLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
            
            // Keyframe 3: Zoom in
            UIView.addKeyframe(withRelativeStartTime: 0.55, relativeDuration: 1.0) {
                self.animatedLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
            
        }, completion: { [self] _ in
            if selectedAnimationIndex != -1 && availableAnimations.allCases[selectedAnimationIndex] == .ZoomInOut {
                self.zoomInOutAnimation()
            }
        })
    }
    
    func rightAndLeftAnimation(){
        
        UIView.animateKeyframes(withDuration: 2, delay: 0, options: [], animations: {
            self.animatedLabel.transform = .identity
            
            // Keyframe 2: Move down and change color to red
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                self.animatedLabel.transform = CGAffineTransformMakeTranslation(30, 0)
            }
            
            // Keyframe 3: Zoom in
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.5) {
                self.animatedLabel.transform = CGAffineTransformMakeTranslation(-30, 0)
            }
            
            // Keyframe 3: Zoom in
            UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                self.animatedLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            }
            
        }, completion: { [self] _ in
            if selectedAnimationIndex != -1 && availableAnimations.allCases[selectedAnimationIndex] == .RightAndLeft {
                self.rightAndLeftAnimation()
            }
        })
    }
    
    func upAndDownAnimation(){
        
        UIView.animateKeyframes(withDuration: 2, delay: 0, options: [], animations: {
           
            // Keyframe 2: Move down and change color to red
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.25) {
                self.animatedLabel.transform = CGAffineTransformMakeTranslation(0, 30)
            }
            
            // Keyframe 3: Zoom in
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.5) {
                self.animatedLabel.transform = CGAffineTransformMakeTranslation(0, -30)
            }
            
            // Keyframe 3: Zoom in
            UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                self.animatedLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            }
            
        }, completion: { [self] _ in
            if selectedAnimationIndex != -1 && availableAnimations.allCases[selectedAnimationIndex] == .upAndDown {
                self.upAndDownAnimation()
            }
        })
    }
    
    func leftToRightAnimation(){
        UIView.animateKeyframes(withDuration: 2, delay: 0, animations: {
            self.animatedLabel.transform = CGAffineTransformMakeTranslation(self.containerview.bounds.width , 0)
            
            // Keyframe 2: Move down and change color to red
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.9) {
                self.animatedLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            }
        }, completion: { [self] _ in
            if selectedAnimationIndex != -1 && availableAnimations.allCases[selectedAnimationIndex] == .leftToRight {
                self.leftToRightAnimation()
            }
        })
    }
    
    func topToBottomAnimation(){
        UIView.animateKeyframes(withDuration: 2, delay: 0, animations: {
            self.animatedLabel.transform = CGAffineTransformMakeTranslation(0 , -self.containerview.bounds.height + 10)
            
            // Keyframe 2: Move down and change color to red
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0) {
                self.animatedLabel.transform = CGAffineTransformMakeTranslation(0, self.containerview.bounds.height - 10)
            }
        }, completion: { [self] _ in
            if selectedAnimationIndex != -1 && availableAnimations.allCases[selectedAnimationIndex] == .topToBottom {
                self.topToBottomAnimation()
            }
        })
    }
    
    
    var frames : [UIImage] = []
    @IBAction func DoneAction(_ sender: Any) {
        index = selectedAnimationIndex
        selectedAnimationIndex = -1
        UIView.animate(withDuration: 0.0) {
            self.animatedLabel.layer.removeAllAnimations()
        }
        
        animateLabel(animType: availableAnimations.allCases[index])
        let animationDuration: TimeInterval = 2.0
        let numberOfFrames = 30
        let interval = animationDuration / TimeInterval(numberOfFrames)
           
           Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
               if self.frames.count >= numberOfFrames {
                   timer.invalidate()
                   self.gotoEditPage()
               } else {
                   self.captureCurrentFrame()
               }
           }
    }
    
    func captureCurrentFrame() {
        if let presentationLayer = containerview.layer.presentation() {
            // Ensure the layer is of type CALayer
            let layer = presentationLayer
            // Begin an image context with the size of the layer
            UIGraphicsBeginImageContextWithOptions(layer.bounds.size, layer.isOpaque, 0.0)
            
            // Render the layer to the image context
            if let context = UIGraphicsGetCurrentContext() {
                layer.render(in: context)
            }
            
            // Retrieve the UIImage from the current image context
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            // End the image context
            UIGraphicsEndImageContext()
            
            // Use the image (for example, you can print it or set it to an UIImageView)
            if let image = image {
                print("Successfully converted presentationLayer to UIImage")
                // Do something with the image, like setting it to an image view
                // imageView.image = image
                frames.append(image)
            } else {
                print("Failed to convert presentationLayer to UIImage")
            }
        }
        
    }
    
    func gotoEditPage(){
        let vc = EditViewController(frames: frames)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension TextInputViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == colorCollectionView {
            return availableColors.count
        }
        if collectionView == fontCollectionView {
            return availableFonts.count
        }
        if collectionView == animateCollectionView {
            return availableAnimations.allCases.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == colorCollectionView {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCollectionViewCell.colorsIdentifier, for: indexPath) as? ColorCollectionViewCell {
                cell.myContainer.backgroundColor = availableColors[indexPath.row]
                
                return cell
            }
            
        }
       
        if collectionView == fontCollectionView {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FontsCollectionViewCell.fontsIdentifier, for: indexPath) as? FontsCollectionViewCell {
                cell.setUp(str: availableFonts[indexPath.row])
                
                return cell
            }
        }
       
        if collectionView == animateCollectionView {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AnimCollectionViewCell.animIdentifier, for: indexPath) as? AnimCollectionViewCell {
                cell.animNameLabel.text = availableAnimations.allCases[indexPath.row].rawValue
                
                return cell
            }
        }
       
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == colorCollectionView {
            animatedLabel.textColor = availableColors[indexPath.row]
        }
        if collectionView == fontCollectionView {
            animatedLabel.font = UIFont(name: availableFonts[indexPath.row], size: 30)
        }
        if collectionView == animateCollectionView {
            if selectedAnimationIndex == indexPath.row {return}
            selectedAnimationIndex = indexPath.row
            animateLabel(animType: availableAnimations.allCases[indexPath.row])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == colorCollectionView {
            return CGSize(width: 24, height: 24)
        }
        if collectionView == fontCollectionView {
            var sz = CGSize(width: 100, height: 24)
            if let font = UIFont(name: availableFonts[indexPath.row], size: 15) {
               let fontAttributes = [NSAttributedString.Key.font: font]
               let text = availableFonts[indexPath.row]
                sz = (text as NSString).size(withAttributes: fontAttributes)
            }
            return CGSize(width: sz.width + 30, height: 24)
        }
        
        if collectionView == animateCollectionView {
            let wid = (collectionView.bounds.width - 24 - 32) / 3
            return CGSize(width: wid, height: 45)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == animateCollectionView {
            return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        }
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}


var availableColors : [UIColor] = [
    .black,
    .white,
    .cyan,
    .blue,
    .magenta,
    .red,
    .yellow,
    .orange,
    .purple,
    .brown,
    .gray,
    .green
]

var availableFonts : [String] = [
    "Arial",
    "Arial-BoldMT",
    "Arial-BoldItalicMT",
    "Arial-ItalicMT",
    "Avenir",
    "Avenir-Black",
    "Avenir-BlackOblique",
    "Avenir-Book",
    "Avenir-BookOblique",
    "Avenir-Heavy",
    "Avenir-HeavyOblique",
    "Avenir-Light",
    "Avenir-LightOblique",
    "Avenir-Medium",
    "Avenir-MediumOblique",
    "Avenir-Oblique",
    "Baskerville",
    "Baskerville-Bold",
    "Baskerville-BoldItalic",
    "Baskerville-Italic",
    "Courier",
    "Courier-Bold",
    "Courier-BoldOblique",
    "Courier-Oblique",
    "Futura",
    "Futura-Bold",
    "Futura-CondensedExtraBold",
    "Futura-CondensedMedium",
    "Futura-Medium",
    "Futura-MediumItalic",
    "Georgia",
    "Georgia-Bold",
    "Georgia-BoldItalic",
    "Georgia-Italic",
    "GillSans",
    "GillSans-Bold",
    "GillSans-BoldItalic",
    "GillSans-Italic",
    "GillSans-Light",
    "GillSans-LightItalic",
    "GillSans-SemiBold",
    "GillSans-SemiBoldItalic",
    "Helvetica",
    "Helvetica-Bold",
    "Helvetica-BoldOblique",
    "Helvetica-Light",
    "Helvetica-LightOblique",
    "Helvetica-Oblique",
    "HiraginoSans-W3",
    "HiraginoSans-W6",
    "MarkerFelt-Thin",
    "Noteworthy",
    "Noteworthy-Bold",
    "Palatino",
    "Palatino-Bold",
    "Palatino-BoldItalic",
    "Palatino-Italic",
    "TrebuchetMS",
    "Trebuchet-BoldItalic",
    "TrebuchetMS-Bold",
    "TrebuchetMS-Italic",
    "Verdana",
    "Verdana-Bold",
    "Verdana-BoldItalic",
    "Verdana-Italic"
]

enum availableAnimations : String, CaseIterable {
    case None = "None"
    case ZoomIn = "ZoomIn"
    case ZoomInOut = "Zoom In-Out"
    case RightAndLeft = "Right & Left"
    case leftToRight = "Left To Right"
    case topToBottom = "Top To Bottom"
    case upAndDown = "Up & Down"
}
