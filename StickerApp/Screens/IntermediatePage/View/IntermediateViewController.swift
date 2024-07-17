//
//  IntermediateViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/20/24.
//

import UIKit
import AVFoundation

class IntermediateViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var loaderView: UIView!
    @IBOutlet weak var currentDurationLimit: UILabel!
    @IBOutlet weak var seekarLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var seekarView: UIView!
    @IBOutlet weak var frameCollectionView: UICollectionView!
    @IBOutlet weak var frameContainerView: UIView!
    @IBOutlet weak var rightSliderTraillingCons: NSLayoutConstraint!
    @IBOutlet weak var leftSliderLeadingCons: NSLayoutConstraint!
    @IBOutlet weak var rightSliderView: UIView!
    @IBOutlet weak var leftSliderView: UIView!
    @IBOutlet weak var sliderLeadingCon: NSLayoutConstraint!
    @IBOutlet weak var sliderContainerView: UIView!
    @IBOutlet weak var sliderView: UIView!
    @IBOutlet weak var playPlauseImageView: UIImageView!
    let avPlayerLayerContainer = AvPlayerLayerContainerView(frame: .zero)
    @IBOutlet weak var containerView: UIView!
    private var cornerpoints =  [CornerpointView]()
    let url : URL
    private var imageCropper: ARImageCropper!
    
    var player : AVPlayer!
    var frames : [Double : UIImage] = [:]
    var times : [CMTime] = []
    var minimumtime : CMTime = .zero {
        didSet {
            currentDurationLimit.text = "\(String(format:"%.1f", minimumtime.seconds)) ~ \(String(format:"%.1f", maximumtime.seconds))s"
        }
    }
    var maximumtime : CMTime = CMTime(seconds: 10, preferredTimescale: 600) {
        didSet {
            currentDurationLimit.text = "\(String(format:"%.1f", minimumtime.seconds)) ~ \(String(format:"%.1f", maximumtime.seconds))s"
        }
    }
    var totalDuration : CMTime = .zero
    var totalPixel : CGFloat = .zero
    let isVideo : Bool
    
    init(url : URL, isVideo : Bool){
        self.url = url
        self.isVideo = isVideo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true
        
        loadPlayer(from: url)
        setConstraints()
        configureCollectionView()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.extractFramesFromVideo(at: self.url)
        }
    }
    
    private func configureCollectionView(){
        let nib = UINib(nibName: frameCollectionViewCell.frameIdentifier, bundle: nil)
        frameCollectionView.register(nib, forCellWithReuseIdentifier: frameCollectionViewCell.frameIdentifier)
        frameCollectionView.delegate = self
        frameCollectionView.dataSource = self
    }
    
    private func setConstraints(){
        sliderContainerView.layer.cornerRadius = 4
        sliderView.layer.cornerRadius = 4
        
        addGestureToView(view: sliderView)
        addGestureToView(view: leftSliderView)
        addGestureToView(view: rightSliderView)
        leftSliderView.tag = 1
        rightSliderView.tag = 2
        sliderView.tag = 3
    }
    
    var sliderPangesture : UIPanGestureRecognizer?
    func addGestureToView(view : UIView){
        view.isUserInteractionEnabled = true
        sliderPangesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        
        guard let sliderPangesture = sliderPangesture else {return}
        sliderPangesture.delegate = self
        view.addGestureRecognizer(sliderPangesture)
    }
    
    private var beginningPoint = CGPoint.zero
    private var leadingPoint = CGFloat.zero
    
    
    @objc func handlePanGesture(_ recognizer : UIPanGestureRecognizer){
        
        guard let view = recognizer.view else {
            return
        }
        
        switch view.tag {
        case 1 : handleLeftSliderRecognizer(recognizer)
        case 2 : handleRightSliderRecognizer(recognizer)
        case 3 : handleSliderRecognizer(recognizer)
        default : break
        }
    }
    
    func handleRightSliderRecognizer(_ recognizer : UIPanGestureRecognizer){
        let touchLocation = recognizer.location(in: view.superview)
        switch recognizer.state {
        case .began:
            self.beginningPoint = touchLocation
            self.leadingPoint = rightSliderTraillingCons.constant
            pauseAction()
        case .changed, .ended:
            var leadingValue = self.leadingPoint + (self.beginningPoint.x - touchLocation.x)
            if leadingValue < 0 {
                leadingValue = 0
            }else if leadingValue > frameContainerView.bounds.width - ( leftSliderLeadingCons.constant + (leftSliderView.bounds.width * 2)) {
                leadingValue = frameContainerView.bounds.width - (leftSliderLeadingCons.constant + (leftSliderView.bounds.width * 2))
            }
            
            rightSliderTraillingCons.constant = leadingValue
            
            let rightInPixel = frameContainerView.bounds.width - (leadingValue + rightSliderView.bounds.width) + frameCollectionView.contentOffset.x
            let timeInseconds = rightInPixel * totalDuration.seconds / totalPixel
            maximumtime = CMTime(seconds: timeInseconds, preferredTimescale: 600)
            
            if recognizer.state == .ended {
                seekarView.isHidden = false
                seekarLeadingConstraint.constant = 0
                player.seek(to: minimumtime, toleranceBefore: .zero, toleranceAfter: .zero)
            }else {
                seekarView.isHidden = true
                player.seek(to: maximumtime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
           
        default : break
        }
        
    }
    
    func handleLeftSliderRecognizer(_ recognizer : UIPanGestureRecognizer){
        let touchLocation = recognizer.location(in: view.superview)
        switch recognizer.state {
        case .began:
            self.beginningPoint = touchLocation
            self.leadingPoint = leftSliderLeadingCons.constant
           pauseAction()
        case .changed, .ended:
            var leadingValue = self.leadingPoint + (touchLocation.x - self.beginningPoint.x)
            if leadingValue < 0 {
                leadingValue = 0
            }else if leadingValue > frameContainerView.bounds.width - (rightSliderView.bounds.width * 2 + rightSliderTraillingCons.constant) {
                leadingValue = frameContainerView.bounds.width - (rightSliderView.bounds.width * 2 + rightSliderTraillingCons.constant)
            }
            leftSliderLeadingCons.constant = leadingValue
           
            let leftInPixel = leftSliderLeadingCons.constant + frameCollectionView.contentOffset.x
            let timeInseconds = leftInPixel * totalDuration.seconds / totalPixel
            minimumtime = CMTime(seconds: timeInseconds, preferredTimescale: 600)
           
            if recognizer.state == .ended {
                seekarView.isHidden = false
                seekarLeadingConstraint.constant = 0
                player.seek(to: minimumtime, toleranceBefore: .zero, toleranceAfter: .zero)
            }else {
                seekarView.isHidden = true
                player.seek(to: minimumtime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        default : break
        }
        
    }
    
    func handleSliderRecognizer(_ recognizer : UIPanGestureRecognizer){
        let touchLocation = recognizer.location(in: view.superview)
        switch recognizer.state {
        case .began:
            self.beginningPoint = touchLocation
            self.leadingPoint = sliderLeadingCon.constant
            pauseAction()
        case .changed, .ended:
            var leadingValue = self.leadingPoint + (touchLocation.x - self.beginningPoint.x)
            if leadingValue < 0 {
                leadingValue = 0
            }else if leadingValue > (sliderContainerView.bounds.width - sliderView.bounds.width) {
                leadingValue = sliderContainerView.bounds.width - sliderView.bounds.width
            }
            sliderLeadingCon.constant = leadingValue
            
            seekVideo(recognizer)
           
        default : break
        }
        
    }
    
    private func seekVideo(_ recognizer : UIPanGestureRecognizer) {
        let frameWidth = frameCollectionView.bounds.width / 10
        let sliderTotalWidth = sliderContainerView.bounds.width - sliderView.bounds.width
        let numberOfFramesLeft = times.count - 10
        let remainingCollectionWidth = CGFloat(numberOfFramesLeft) * frameWidth
        let tmp = remainingCollectionWidth * sliderLeadingCon.constant / sliderTotalWidth
        
        frameCollectionView.contentOffset.x = tmp
        
        let leftInPixel = leftSliderLeadingCons.constant + frameCollectionView.contentOffset.x
        let timeInseconds = leftInPixel * totalDuration.seconds / totalPixel
        minimumtime = CMTime(seconds: timeInseconds, preferredTimescale: 600)
          
        let rightInPixel = frameContainerView.bounds.width - (rightSliderTraillingCons.constant + rightSliderView.bounds.width) + frameCollectionView.contentOffset.x
        let timeInseconds2 = rightInPixel * totalDuration.seconds / totalPixel
        maximumtime = CMTime(seconds: timeInseconds2, preferredTimescale: 600)
        
        player.seek(to: minimumtime, toleranceBefore: .zero, toleranceAfter: .zero)
        if recognizer.state == .changed {
            seekarView.isHidden = true
        }else{
            seekarView.isHidden = false
        }
        seekarLeadingConstraint.constant = 0
    }
    
    private func loadPlayer(from url : URL){
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        totalDuration = asset.duration
        containerView.addSubview(avPlayerLayerContainer)
        avPlayerLayerContainer.backgroundColor = UIColor.clear
        guard let testPlayerLayer = avPlayerLayerContainer.layer as? AVPlayerLayer else {return }
        testPlayerLayer.player = player
        testPlayerLayer.needsDisplayOnBoundsChange = true
        testPlayerLayer.videoGravity = .resizeAspect
        avPlayerLayerContainer.translatesAutoresizingMaskIntoConstraints = false

        let leadingConstraint = avPlayerLayerContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        let trailingConstraint = avPlayerLayerContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        let bottomConstraint = avPlayerLayerContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        let topConstarint = avPlayerLayerContainer.topAnchor.constraint(equalTo: containerView.topAnchor)
        NSLayoutConstraint.activate([ leadingConstraint, trailingConstraint, bottomConstraint, topConstarint ])
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let time = CMTimeMakeWithSeconds(0, preferredTimescale: asset.duration.timescale)
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
            if let cgImage = cgImage {
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    self.initializeCropper(with: uiImage)
                }
            } else if let error = error {
                print("Error generating image: \(error.localizedDescription)")
            }
        }
        
        NotificationCenter.default
            .addObserver(self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: Int32(NSEC_PER_SEC)), queue: DispatchQueue.main) { [weak self] (CMTime) -> Void in
            if let self = self {
                
                if self.player?.currentItem?.status == .readyToPlay {
                    if CMTime >= maximumtime {
                        pauseAction()
                        
                        return
                    }
                    
                    if player?.rate != 0 {
                        let diff = (frameContainerView.bounds.width - (rightSliderView.bounds.width + rightSliderTraillingCons.constant)) - (leftSliderLeadingCons.constant + leftSliderView.bounds.width)
                        let curPosition = diff / (maximumtime.seconds - minimumtime.seconds) * (CMTime.seconds - minimumtime.seconds)
                        seekarLeadingConstraint.constant = curPosition
                    }
                }
            }
        }
        
        player?.volume = 0
        player?.play()
    }
    
    @objc func playerDidFinishPlaying(){
        pauseAction()
    }
    
    func initializeCropper(with img : UIImage){
        // Initialize the ARImageCropper instance
        imageCropper = ARImageCropper(frame: containerView.bounds)
        imageCropper.backgroundColor = .clear
        
        // Set the properties for the image cropper
        imageCropper.image = img
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
    
    func extractFramesFromVideo(at url: URL) {
        let asset = AVAsset(url: url)
        let assetDuration = CMTimeGetSeconds(asset.duration)
        
        var frameCount = 0
        if asset.duration.seconds <= 10 {
            frameCount = 10
            sliderView.isUserInteractionEnabled = false
            sliderView.backgroundColor = .gray
            maximumtime = asset.duration
        }else {
            frameCount = Int(ceil(asset.duration.seconds))
            maximumtime = CMTime(seconds: 10, preferredTimescale: 600)
        }
        
        times = stride(from: 0, to: assetDuration, by: assetDuration / Double(frameCount)).map {
            CMTimeMakeWithSeconds($0, preferredTimescale: asset.duration.timescale)
        }
        
        totalPixel = CGFloat(times.count) * (frameCollectionView.bounds.width / 10)
        extractFrames(at: times, from: asset)
    }
    
    func extractFrames(at times: [CMTime], from asset: AVAsset) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        let dispatchGroup = DispatchGroup()

        for time in times {
            dispatchGroup.enter()
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
                if let cgImage = cgImage {
                    let uiImage = UIImage(cgImage: cgImage)
                    self.frames[time.seconds] = uiImage.normalizeImageOrientation()
                    
                    DispatchQueue.main.async {
                        self.frameCollectionView.reloadData()
                    }
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
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playPauseButtonAction(_ sender: Any) {
        if player?.rate == 0 {
           playAction()
        }else {
           pauseAction()
        }
    }
    
    private func playAction(){
        if (player.currentItem?.duration)! <= player.currentTime() || maximumtime <= player.currentTime() {
            player.seek(to: minimumtime, toleranceBefore: .zero, toleranceAfter: .zero)
            seekarLeadingConstraint.constant = 0
        }
        player?.play()
        playPlauseImageView.image = UIImage(named: "pauseButton")
    }
    
    private func pauseAction(){
        player?.pause()
        playPlauseImageView.image = UIImage(named: "playButton")
    }
    
    @IBAction func NextAction(_ sender: Any) {
        let croppedRect = imageCropper.croppedImage()

        loaderView.isHidden = false
        let asset = AVAsset(url: url)
        let assetDuration = CMTimeGetSeconds(asset.duration)
        
        guard let track = asset.tracks(withMediaType: .video).first else {
               // Handle error (e.g., no video track found)
               return
           }
           
        let frameRate = track.nominalFrameRate
        let frm = max(1, (Float(maximumtime.seconds - minimumtime.seconds) * frameRate) / 60)
        let frameCount = Int(assetDuration * Double(frameRate) / Double(frm))
        
        let frameTimes = stride(from: minimumtime.seconds, to: maximumtime.seconds, by: assetDuration / Double(frameCount)).map {
            CMTimeMakeWithSeconds($0, preferredTimescale: asset.duration.timescale)
        }
        
        extractFramesForEditPage(at: frameTimes, from: asset, cropRect: croppedRect) { frames in
            DispatchQueue.main.async {
                if frames.count > 0 {
                    let vc = EditViewController(frames: frames, curFeature: .video)
                    vc.framePerSecond = frames.count / 2
                    self.navigationController?.pushViewController(vc, animated: true)
                }else {
                    self.hideLoaderView()
                }
            }
        }
    }
    
    func extractFramesForEditPage(at times: [CMTime], from asset: AVAsset, cropRect : CGRect?, completion : @escaping ([UIImage]) -> ()) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
//        imageGenerator.maximumSize = CGSize(width: 512, height: 512)
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        var frames : [UIImage] = []
        let dispatchGroup = DispatchGroup()

        for time in times {
            dispatchGroup.enter()
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
                if let cgImage = cgImage {
                    var uiImage = UIImage(cgImage: cgImage)
                    if cropRect != nil {
                        uiImage = uiImage.cropImage(toRect: cropRect!) ?? uiImage
                        uiImage = uiImage.getResizedImage(maxSize: 280) ?? uiImage
                    }
                    frames.append(uiImage)
                } else if let error = error {
                    
                    print("Error generating image: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        
        
        dispatchGroup.notify(queue: .main) {
            // This block is called when all tasks have completed
            completion(frames)
        }
    }
    
    func hideLoaderView(){
        DispatchQueue.main.async {
            self.loaderView.isHidden = true
        }
    }
}

extension IntermediateViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        times.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: frameCollectionViewCell.frameIdentifier, for: indexPath) as? frameCollectionViewCell {
            if (frames[times[indexPath.row].seconds] != nil) {
                cell.frameImageView.image = frames[times[indexPath.row].seconds]
            }else {
                cell.frameImageView.image = nil
            }
            
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (collectionView.bounds.width / 10), height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}


class AvPlayerLayerContainerView: UIView {
    
    override public class var layerClass: Swift.AnyClass {
        return AVPlayerLayer.self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
