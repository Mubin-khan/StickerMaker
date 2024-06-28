//
//  TextInputViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/24/24.
//

import UIKit

class TextInputViewController: UIViewController {

    @IBOutlet weak var keyboardContainerHeightCon: NSLayoutConstraint!
    @IBOutlet weak var sampleTextView: UITextView!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var strokeCollectionView: UICollectionView!
    @IBOutlet weak var colorContainerCollectionView: UICollectionView!
    @IBOutlet weak var strokeView: UIView!
    @IBOutlet weak var textColorView: UIView!
    @IBOutlet weak var animatedTextView: UIView!
    @IBOutlet weak var inputTextContainer: UIView!
    @IBOutlet weak var animateCollectionView: UICollectionView!
    @IBOutlet weak var featureCollectionView: UICollectionView!
    @IBOutlet weak var colorCollectionView: UICollectionView!
    @IBOutlet weak var fontCollectionView: UICollectionView!
    
    var selectedAnimationIndex = 0
    let animatedLabel: CustomTextLabel = {
        let label = CustomTextLabel()
        label.text = "Welcome"
        label.font = UIFont(name: "Arial Bold", size: 40)
        label.textAlignment = .center
        label.alpha = 1  // Start with the label invisible
        label.textColor = .red
        label.numberOfLines = 0
        label.strokeColor = .black
        label.strokeLineWidth = 2
        label.shadowColor = .black
        label.shadowOffset = CGSizeMake(0, 2.5)
        label.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
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
        sampleTextView.delegate = self
        
        // keyboard observer
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handle(keyboardShowNotification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        // keyboard observer
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handle(keyboardHideNotification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        
        showKeyboard()
    }
    
    @objc
    private func handle(keyboardShowNotification notification: Notification) {
        animateWithKeyboard(notification: notification as NSNotification){ [self] keyboardFrame in
            let currentHeight : CGFloat = keyboardFrame.height
            keyboardContainerHeightCon?.constant = currentHeight
            self.view.layoutIfNeeded()
        }
    }
    
    @objc
    private func handle(keyboardHideNotification notification: Notification) {
        animateWithKeyboard(notification: notification as NSNotification){ [self] keyboardFrame in
            let currentHeight : CGFloat = 326 //keyboardFrame.height + getTextViewNavHeight()
            keyboardContainerHeightCon?.constant = currentHeight
            self.view.layoutIfNeeded()
        }
    }
    
    func animateWithKeyboard(
        notification: NSNotification,
        animations: ((_ keyboardFrame: CGRect) -> Void)?
    ) {
        // Extract the duration of the keyboard animation
        let durationKey = UIResponder.keyboardAnimationDurationUserInfoKey
        let duration = notification.userInfo![durationKey] as! Double
        
        // Extract the final frame of the keyboard
        let frameKey = UIResponder.keyboardFrameEndUserInfoKey
        let keyboardFrameValue = notification.userInfo![frameKey] as! NSValue
        
        // Extract the curve of the iOS keyboard animation
        let curveKey = UIResponder.keyboardAnimationCurveUserInfoKey
        let curveValue = notification.userInfo![curveKey] as! Int
        let curve = UIView.AnimationCurve(rawValue: curveValue)!
        
        // Create a property animator to manage the animation
        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: curve
        ) {
            // Perform the necessary animation layout updates
            animations?(keyboardFrameValue.cgRectValue)
            
        }
        
        // Start the animation
        animator.startAnimation()
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
            containerview.widthAnchor.constraint(equalToConstant: inputTextContainer.bounds.width - 60),
            containerview.heightAnchor.constraint(equalToConstant: inputTextContainer.bounds.height - 60)
        ])
        
        containerview.addSubview(animatedLabel)
        containerview.clipsToBounds = true
        animatedLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animatedLabel.leadingAnchor.constraint(equalTo: containerview.leadingAnchor, constant: 30),
            animatedLabel.trailingAnchor.constraint(equalTo: containerview.trailingAnchor, constant: -30),
            animatedLabel.topAnchor.constraint(equalTo: containerview.topAnchor, constant: 30),
            animatedLabel.bottomAnchor.constraint(equalTo: containerview.bottomAnchor, constant: -30)
        ])
        
    }
    
    private func configureCollectionView(){
        let nib = UINib(nibName: ColorCollectionViewCell.colorsIdentifier, bundle: nil)
        colorCollectionView.register(nib, forCellWithReuseIdentifier: ColorCollectionViewCell.colorsIdentifier)
        colorCollectionView.delegate = self
        colorCollectionView.dataSource = self
        
        colorContainerCollectionView.register(nib, forCellWithReuseIdentifier: ColorCollectionViewCell.colorsIdentifier)
        colorContainerCollectionView.delegate = self
        colorContainerCollectionView.dataSource = self
        
        strokeCollectionView.register(nib, forCellWithReuseIdentifier: ColorCollectionViewCell.colorsIdentifier)
        strokeCollectionView.delegate = self
        strokeCollectionView.dataSource = self
        
        let nib1 = UINib(nibName: FontsCollectionViewCell.fontsIdentifier, bundle: nil)
        fontCollectionView.register(nib1, forCellWithReuseIdentifier: FontsCollectionViewCell.fontsIdentifier)
        fontCollectionView.delegate = self
        fontCollectionView.dataSource = self
        
        let nib3 = UINib(nibName: AnimCollectionViewCell.animIdentifier, bundle: nil)
        animateCollectionView.register(nib3, forCellWithReuseIdentifier: AnimCollectionViewCell.animIdentifier)
        animateCollectionView.delegate = self
        animateCollectionView.dataSource = self
        
        let nib4 = UINib(nibName: TextFeatureCollectionViewCell.textFeatureidentifier, bundle: nil)
        featureCollectionView.register(nib4, forCellWithReuseIdentifier: TextFeatureCollectionViewCell.textFeatureidentifier)
        featureCollectionView.delegate = self
        featureCollectionView.dataSource = self
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
            case .Flip : flipAnimation()
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
    
    func flipAnimation() {
        UIView.animateKeyframes(withDuration: 2, delay: 0, options: [], animations: {
            // Keyframe 1: Rotate halfway (flip)
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.animatedLabel.transform = CGAffineTransform(scaleX: 0.02, y: 1)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.animatedLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            
        }, completion: { [self] _ in
            if selectedAnimationIndex != -1 && availableAnimations.allCases[selectedAnimationIndex] == .Flip {
                self.flipAnimation()
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
        if selectedAnimationIndex != -1 {
            index = selectedAnimationIndex
            selectedAnimationIndex = -1
        }
        
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
    
    var is3D : Bool = true
    @IBAction func threeDButtonAction(_ sender: Any) {
        is3D = !is3D
        if is3D {
            is3DAction()
            checkMarkImageView.image = UIImage(named: "check")
        }else {
            isNormalAction()
            checkMarkImageView.image = UIImage(named: "close")
        }
//        strokeSliderWidth = strokeSliderWidth
    }
    
    var strokeSliderWidth : CGFloat = 2 {
        didSet {
            if is3D {
               is3DAction()
            }else {
                isNormalAction()
            }
            
            animatedLabel.setNeedsDisplay()
        }
    }
    
    func is3DAction(){
        animatedLabel.strokeLineWidth = strokeSliderWidth
        animatedLabel.shadowOffset.height = CGFloat(rangeConverter(value: Float(strokeSliderWidth), oldMinRange: 0, oldMaxRange: 2, expMinRange: 0, expMaxRange: 3))
    }
    
    func isNormalAction(){
        animatedLabel.strokeLineWidth = CGFloat(rangeConverter(value: Float(strokeSliderWidth), oldMinRange: 0, oldMaxRange: 2, expMinRange: 0, expMaxRange: 7))
        animatedLabel.shadowOffset.height = 0
    }
    
    func rangeConverter(value: Float, oldMinRange: Float, oldMaxRange: Float, expMinRange: Float, expMaxRange: Float) -> Float {
        
        let newValue = (((value - oldMinRange) * (expMaxRange - expMinRange)) / (oldMaxRange - oldMinRange)) + expMinRange
        return newValue
    }
    
    @IBAction func strokeSizechangeAction(_ sender: UISlider, forEvent event: UIEvent) {
        strokeSliderWidth = CGFloat(sender.value)
    }
    
    func showSpecificView(type : featues) {
        switch type {
        case .Animation : showAnimationView()
        case .color : showColorView()
        case .stroke : showStrokeView()
        case .keyboard : showKeyboard()
        }
    }
    
    private func hideOtherView() {
        animatedTextView.isHidden = true
        textColorView.isHidden = true
        strokeView.isHidden = true
        sampleTextView.resignFirstResponder()
    }
    
    private func showAnimationView(){
        if !animatedTextView.isHidden {
            return
        }
        selectedAnimationIndex = index
        animateLabel(animType: availableAnimations.allCases[selectedAnimationIndex])
        hideOtherView()
        animatedTextView.isHidden = false
    }
    
    private func showColorView(){
        stopAnimation()
        hideOtherView()
        textColorView.isHidden = false
    }
    
    private func showStrokeView(){
        stopAnimation()
        hideOtherView()
        strokeView.isHidden = false
    }
    
    private func showKeyboard(){
        stopAnimation()
        hideOtherView()
        sampleTextView.becomeFirstResponder()
    }
    
    func stopAnimation(){
        if selectedAnimationIndex != -1 {
            index = selectedAnimationIndex
            selectedAnimationIndex = -1
        }
        UIView.animate(withDuration: 0.0) {
            self.animatedLabel.layer.removeAllAnimations()
            self.animatedLabel.transform = .identity
        }
    }
    
    func gotoEditPage(){
        let vc = EditViewController(frames: frames)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
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
        if collectionView == featureCollectionView {
            return featues.allCases.count
        }
        if collectionView == colorContainerCollectionView {
            return availableColors.count
        }
        if collectionView == strokeCollectionView {
            return availableColors.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == colorCollectionView  || collectionView == colorContainerCollectionView || collectionView == strokeCollectionView{
            
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
        
        if collectionView == featureCollectionView {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextFeatureCollectionViewCell.textFeatureidentifier, for: indexPath) as? TextFeatureCollectionViewCell {
                cell.featueTitle.text = featues.allCases[indexPath.row].rawValue
                
                return cell
            }
        }
       
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == colorCollectionView {
            animatedLabel.textColor = availableColors[indexPath.row]
            animatedLabel.setNeedsDisplay()
        }
        if collectionView == fontCollectionView {
            animatedLabel.font = UIFont(name: availableFonts[indexPath.row], size: 40)
            animatedLabel.setNeedsDisplay()
        }
        if collectionView == animateCollectionView {
            if selectedAnimationIndex == indexPath.row {return}
            selectedAnimationIndex = indexPath.row
            animateLabel(animType: availableAnimations.allCases[indexPath.row])
        }
        
        if collectionView == featureCollectionView {
            showSpecificView(type: featues.allCases[indexPath.row])
        }
        
        if collectionView == colorContainerCollectionView {
            animatedLabel.textColor = availableColors[indexPath.row]
        }
        
        if collectionView == strokeCollectionView {
            animatedLabel.strokeColor = availableColors[indexPath.row]
            animatedLabel.shadowColor = availableColors[indexPath.row]
            animatedLabel.setNeedsDisplay()
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
        
        if collectionView == featureCollectionView {
            return CGSize(width: 90, height: collectionView.bounds.height)
        }
        
        if collectionView == colorContainerCollectionView {
            return CGSize(width: 30, height: 30)
        }
        
        if collectionView == strokeCollectionView {
            return CGSize(width: 30, height: 30)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView === featureCollectionView {
           let tmp = collectionView.bounds.width - CGFloat(40) - CGFloat(90 * featues.allCases.count)
            return tmp / CGFloat(featues.allCases.count - 1)
        }
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == animateCollectionView {
            return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        }
        if collectionView == featureCollectionView {
            return  UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
        if collectionView == colorContainerCollectionView || collectionView == strokeCollectionView {
            return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        }
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

extension TextInputViewController : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count >= 20 {
            return
        }
        animatedLabel.text = textView.text
    }
}

var availableColors: [UIColor] = [
    UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1), // white
    UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1), // black
    UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1), // Red
    UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1), // Green
    UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1), // Blue
    UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1), // Yellow
    UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1), // Cyan
    UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1), // Magenta
    UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1), // Gray
    UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1), // Dark Red
    UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1), // Dark Green
    UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1), // Dark Blue
    UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1), // Orange
    UIColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1), // Purple
    UIColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1), // Teal
    UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1), // Olive
    UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1), // Light Gray
    UIColor(red: 0.75, green: 0.0, blue: 0.0, alpha: 1), // Light Red
    UIColor(red: 0.0, green: 0.75, blue: 0.0, alpha: 1), // Light Green
    UIColor(red: 0.0, green: 0.0, blue: 0.75, alpha: 1), // Light Blue
    UIColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1), // Light Orange
    UIColor(red: 0.75, green: 0.0, blue: 0.75, alpha: 1), // Light Purple
    UIColor(red: 0.0, green: 0.75, blue: 0.75, alpha: 1), // Light Teal
    UIColor(red: 0.75, green: 0.75, blue: 0.0, alpha: 1), // Light Olive
    UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1), // Forest Green
    UIColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1), // Brick Red
    UIColor(red: 0.2, green: 0.2, blue: 0.6, alpha: 1), // Navy Blue
    UIColor(red: 0.6, green: 0.6, blue: 0.2, alpha: 1), // Mustard
    UIColor(red: 0.2, green: 0.6, blue: 0.6, alpha: 1), // Aquamarine
    UIColor(red: 0.6, green: 0.2, blue: 0.6, alpha: 1), // Plum
    UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1), // Dim Gray
    UIColor(red: 0.4, green: 0.0, blue: 0.0, alpha: 1), // Brown
    UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1), // Dark Green
    UIColor(red: 0.0, green: 0.0, blue: 0.4, alpha: 1), // Midnight Blue
    UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1), // Carrot Orange
    UIColor(red: 0.4, green: 0.0, blue: 0.4, alpha: 1), // Indigo
    UIColor(red: 0.0, green: 0.4, blue: 0.4, alpha: 1), // Dark Cyan
    UIColor(red: 0.4, green: 0.4, blue: 0.0, alpha: 1), // Dark Olive
    UIColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1), // Light Green
    UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1), // Rosy Brown
    UIColor(red: 0.3, green: 0.3, blue: 0.7, alpha: 1), // Royal Blue
    UIColor(red: 0.7, green: 0.7, blue: 0.3, alpha: 1), // Khaki
    UIColor(red: 0.3, green: 0.7, blue: 0.7, alpha: 1), // Turquoise
    UIColor(red: 0.7, green: 0.3, blue: 0.7, alpha: 1), // Orchid
    UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1), // Crimson
    UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1), // Lime Green
    UIColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 1), // Deep Blue
    UIColor(red: 0.8, green: 0.8, blue: 0.2, alpha: 1), // Golden Yellow
    UIColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 1), // Bright Cyan
    UIColor(red: 0.8, green: 0.2, blue: 0.8, alpha: 1)  // Hot Pink
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
    case Flip = "Flip"
}

enum featues : String, CaseIterable {
    case keyboard = "Keyboard"
    case Animation = "Anim Text"
    case color = "Color"
    case stroke = "Stroke"
}
