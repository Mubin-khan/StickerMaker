//
//  EditViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/18/24.
//

import UIKit
import MobileCoreServices
import WebPKit
import SDWebImage
import SDWebImageWebPCoder



class EditViewController: UIViewController {

    @IBOutlet weak var sdwebimg: SDAnimatedImageView!
    @IBOutlet weak var editFeatureView: UIView!
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var borderViewWidthCon: NSLayoutConstraint!
    @IBOutlet weak var borderViewHeightCon: NSLayoutConstraint!
    
    @IBOutlet weak var strokeColorCollectionView: UICollectionView!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var contentImageHeightCon: NSLayoutConstraint!
    @IBOutlet weak var contentImageWidthCon: NSLayoutConstraint!
    @IBOutlet weak var container: UIView!
    
    lazy var displayLink: CADisplayLink = CADisplayLink(target: self,
                                                      selector: #selector(displayLinkFired(link:)))
    
    var framePerSecond : Int = 15
    var curFeature : GifFeatue
    var borderWidth : CGFloat = 5 {
        didSet {
            borderViewWidthCon.constant = borderWidth
            borderViewHeightCon.constant = borderWidth
            borderView.layer.cornerRadius = borderWidth / 2
        }
    }
    
    var borderColor : UIColor = .white {
        didSet {
            borderView.backgroundColor = borderColor
        }
    }
    
    var frames : [UIImage] = []
    var currentFrameNumber : Int = 0
    
    init(frames : [UIImage], curFeature : GifFeatue) {
        self.frames = frames
        self.curFeature = curFeature
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        displayLink.isPaused = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true
        
        self.displayLink.add(to: .main, forMode: .common)
        self.displayLink.preferredFramesPerSecond = framePerSecond
 
        let availableWidth = 250
        let sz = frames[0].size.calculateFinalSize(in: CGSize(width: availableWidth, height: availableWidth))
        contentImageWidthCon.constant = sz.width
        contentImageHeightCon.constant = sz.height
        borderView.layer.cornerRadius = 2.5
        
        configureCollectionView()
        
        if curFeature == .text {
            editFeatureView.isHidden = true
            borderView.isHidden = true
        }
    }
    
    private func configureCollectionView(){
        let nib = UINib(nibName: ColorCollectionViewCell.colorsIdentifier, bundle: nil)
        strokeColorCollectionView.register(nib, forCellWithReuseIdentifier: ColorCollectionViewCell.colorsIdentifier)
        strokeColorCollectionView.delegate = self
        strokeColorCollectionView.dataSource = self
    }

    @objc func displayLinkFired(link: CADisplayLink) {
        contentImageView.image = frames[currentFrameNumber]
        currentFrameNumber += 1;
        print(currentFrameNumber)
        if currentFrameNumber >= frames.count {
            currentFrameNumber = 0
        }
    }
    
    
    
    @IBAction func backAction(_ sender: Any) {
        displayLink.invalidate()
        if curFeature == .gif {
            navigationController?.popToRootViewController(animated: true)
        }else if curFeature == .text {
            dismiss(animated: true)
        }
        else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func strokeWidthChangeAction(_ sender: UISlider, forEvent event: UIEvent) {
        borderWidth = CGFloat(sender.value * 20)
    }
    
    @IBAction func speedChangeAction(_ sender: UISlider, forEvent event: UIEvent) {
        self.displayLink.preferredFramesPerSecond = Int(sender.value * 30) + 1
    }
    
    
    @IBAction func doneAction(_ sender: Any) {
        displayLink.isPaused = true
        var finalImages : [UIImage] = []
        
        let tempW = borderWidth * frames[0].size.width / contentImageWidthCon.constant
        let tempH = borderWidth * frames[0].size.height / contentImageHeightCon.constant
        
        let backImageSize = CGSize(width: frames[0].size.width + tempW, height: frames[0].size.height + tempH)
        let backImage = borderView.toImage().resize(backImageSize)
        
        let maxKb = 1
        
        for img in frames {
            if let bgImage = backImage, let outputImg = imageWithBackgroundMerging(bgImage: bgImage, topImage: img){
//                let imageV = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 512, height: 512)))
//                imageV.backgroundColor = .clear
//                imageV.tintColor = .clear
//                imageV.contentMode = .scaleAspectFit
//                imageV.image = outputImg
//                
//                let finalImg = imageV.toImage()
//                if let fImage = outputImg.compressToMaxKB(Double(maxKb)) {
                    finalImages.append(outputImg)
//                }
            }
        }
//        createWebP(from: finalImages)
        let gifUrl = createAnimatedGIF(with: finalImages, duration: 2)
        
        // Usage example
        if let gifUrl = gifUrl, let gifData = try? Data(contentsOf: gifUrl) {
            let sizeInKB = getGifSizeInKB(gifData: gifData)
            print(sizeInKB)
            let vc = StickersViewController(isAnimated: true, fileurl: gifUrl)
            navigationController?.pushViewController(vc, animated: true)
        }
       
    }
    
    // Function to get the size of a GIF in KB
    func getGifSizeInKB(gifData: Data) -> Double {
        let bytes = Double(gifData.count)
        let kilobytes = bytes / 1024
        return kilobytes
    }
    
    func createAnimatedGIF(with images: [UIImage], duration: TimeInterval, loopCount: Int = 0) -> URL? {
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: loopCount]]
        let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: duration / Double(images.count)]]
        
        let temporaryFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).gif")
        guard let destination = CGImageDestinationCreateWithURL(temporaryFileURL as CFURL, kUTTypeGIF, images.count, nil) else {
            return nil
        }
        
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
        
        for image in images {
            CGImageDestinationAddImage(destination, image.cgImage!, frameProperties as CFDictionary)
        }
        
        if !CGImageDestinationFinalize(destination) {
            return nil
        }
        
        let unquename = UUID().uuidString
        guard let permanetfolderurl = ImageSaveRetrieveManager.shared.getGifFolderUrl() else {
            return nil
        }
        let permanentDestination = permanetfolderurl.appendingPathComponent(unquename).appendingPathExtension("gif")
        // Use FileManager to move the file to the permanent destination
            do {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: permanentDestination.path) {
                    try fileManager.removeItem(at: permanentDestination) // Remove existing file at destination if it exists
                }
                try fileManager.moveItem(at: temporaryFileURL, to: permanentDestination)
                return permanentDestination
            } catch {
                print("Error moving file to permanent destination: \(error)")
                return nil
            }
//        return permanentDestination
    }
    
    func imageWithBackgroundMerging(bgImage : UIImage, topImage : UIImage) -> UIImage? {
       guard let bgCiImage = bgImage.toCIImage(),
             let topCiImage = topImage.toCIImage() else {return nil}
        
        let outputCiImage = combineTwoCIImage(backgroundImage: bgCiImage, foregroundImage: topCiImage)
        return outputCiImage?.toUIImage()
    }
    
    func combineTwoCIImage(backgroundImage : CIImage, foregroundImage : CIImage ) -> CIImage? {
        let xx = (backgroundImage.extent.size.width - foregroundImage.extent.size.width) / 2
        let yy = (backgroundImage.extent.size.height - foregroundImage.extent.size.height) / 2
        
        let filter = CIFilter(name: "CISourceOverCompositing")
        filter?.setValue(foregroundImage, forKey: "inputImage")
        filter?.setValue(backgroundImage, forKey: "inputBackgroundImage")
        filter?.setValue(foregroundImage.transformed(by: CGAffineTransformMakeTranslation(xx, yy)), forKey: kCIInputImageKey )
        return filter?.outputImage
    }
    
  
//    func createWebP(from images: [UIImage])  {
//        var frames : [SDImageFrame] = []
//        
//        let duration : Double = 1 / (Double(images.count) / 2)
//        for image in images {
//            let sdf = SDImageFrame(image: image, duration: duration)
//            frames.append(sdf)
//        }
//        
//        if let webdata = SDImageWebPCoder.shared.encodedData(with: frames, loopCount: 0, format: .webP, options: [.encodeMaxFileSize: 1024 * 20, .encodeWebPPartitionLimit : 100, .encodeCompressionQuality : 0.3]) {
//            if let url = saveWebPDataToDocumentsDirectory(webPData: webdata, filename: "kdhskskskksks") {
//                let vc = StickersViewController()
//                vc.fileurl = url
//                navigationController?.pushViewController(vc, animated: true)
//            }
//            
//        }
//
//       
//
//    }
    
    func retrieveDataFromDocumentsDirectory(filename: String) -> Data? {
        do {
            // Get the URL of the documents directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

            // Append the filename to the documents directory URL
            let fileURL = documentsDirectory.appendingPathComponent(filename)

            // Read the data from the file
            let data = try Data(contentsOf: fileURL)
            
            return data
        } catch {
            print("Error retrieving data from documents directory: \(error)")
            return nil
        }
    }
    
    func saveWebPDataToDocumentsDirectory(webPData: Data, filename: String) -> URL? {
        do {
            // Get the URL of the documents directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

            // Append the filename to the documents directory URL
            let fileURL = documentsDirectory.appendingPathComponent(filename)

            // Write the data to the file
            try webPData.write(to: fileURL)

            print("WebP file saved successfully at: \(fileURL.path)")

            return fileURL
        } catch {
            print("Error saving WebP file: \(error)")
            return nil
        }
    }
    
}


extension EditViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCollectionViewCell.colorsIdentifier, for: indexPath) as? ColorCollectionViewCell {
            cell.myContainer.backgroundColor = availableColors[indexPath.row]
            
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 30, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        borderColor = availableColors[indexPath.row]
    }
}


extension UIImage {
    func compressToMaxKB(_ maxKB: Double) -> UIImage? {
        let currentSize = Double(self.jpegData(compressionQuality: 1)?.count ?? 0)
        let quality: CGFloat = (maxKB * 1000) / currentSize
        guard let data = self.jpegData(compressionQuality: quality) else {
            return nil
            
        }
        return UIImage(data: data)
    }
}
