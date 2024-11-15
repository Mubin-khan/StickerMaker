//
//  StickersViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/1/24.
//

import UIKit
import Messages
import MobileCoreServices
import Kingfisher
import SDWebImageWebPCoder

class StickersViewController: UIViewController {

   
    @IBOutlet weak var pngImgView: UIImageView!
   
    @IBOutlet weak var animatedImgVw: SDAnimatedImageView!
    @IBOutlet weak var stickerContainer: UIView!
    var stickers: [MSSticker] = []
    var fileName : String
    var isAnimated : Bool
    
    init(isAnimated : Bool, fileName : String){
        self.isAnimated  = isAnimated
        self.fileName = fileName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true
//        setupStickerBrowser()
        
//        if let url = gifUrl {
//            let imageUrls = ImageSaveRetrieveManager.shared.retrieveAllImagesFromFolder(folderName: ImageSaveRetrieveManager.gifStickersUrlFoldername)
//            for imageUrl in imageUrls {
//                if let sticker = makeSticker(with: imageUrl) {
//                    stickers.append(sticker)
//                }
//            }
//        }
//        
//        
//        if let url = imgUrl {
//            let imageUrls = ImageSaveRetrieveManager.shared.retrieveAllImagesFromFolder(folderName: ImageSaveRetrieveManager.imageStickersUrlFoldername)
//            for imageUrl in imageUrls {
//                if let sticker = makeSticker(with: imageUrl) {
//                    stickers.append(sticker)
//                }
//            }
//        }
        
//            guard let data = try? Data(contentsOf: fileurl) else {return}
            
        if isAnimated {
//            animatedImgVw.kf.setImage(with: fileurl)
            let data = retrieveDataFromDocumentsDirectory(filename: fileName)
            let image = SDImageWebPCoder.shared.decodedImage(with: data, options: [:])
            animatedImgVw.image = image
        }else {
            let img = ImageSaveRetrieveManager.shared.retrieveImageFromDocumentsFolder(imageName: fileName, foldername: ImageSaveRetrieveManager.imageStickersUrlFoldername)
            
            pngImgView.image = img
        }
    }
    
    
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
    
    func makeSticker(with gifURL : URL) -> MSSticker? {
        do {
            let sticker = try MSSticker(contentsOfFileURL: gifURL, localizedDescription: "Animated Sticker")
            return sticker
        } catch {
            print("Failed to create sticker: \(error)")
            return nil
        }
    }
    
    func setupStickerBrowser() {
        let stickerBrowser = MSStickerBrowserViewController(stickerSize: .regular)
        addChild(stickerBrowser)
        stickerContainer.addSubview(stickerBrowser.view)
        stickerBrowser.didMove(toParent: self)
        stickerBrowser.stickerBrowserView.backgroundColor = UIColor.clear
        stickerBrowser.stickerBrowserView.dataSource = self
    }
    
    func createStickers(from images: [UIImage]) -> [MSSticker]? {
         var stickers: [MSSticker] = []
         
         for (index, image) in images.enumerated() {
             if let sticker = createSticker(from: image, index: index) {
                 stickers.append(sticker)
             }
         }
         
         return stickers
     }

    func createSticker(from image: UIImage, index: Int) -> MSSticker? {
           let fileManager = FileManager.default
           let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
           let stickerDirectory = tempDirectory.appendingPathComponent("stickers1", isDirectory: true)
           
           do {
               try fileManager.createDirectory(at: stickerDirectory, withIntermediateDirectories: true, attributes: nil)
               
               let stickerPath = stickerDirectory.appendingPathComponent("sticker1\(index).png")
               if let imageData = image.pngData() {
                   try imageData.write(to: stickerPath)
                   let sticker = try MSSticker(contentsOfFileURL: stickerPath, localizedDescription: "Sticker1 \(index)")
                   return sticker
               }
           } catch {
               print("Failed to create sticker: \(error)")
               return nil
           }
           
           return nil
       }
    
    func createAnimatedSticker(from images: [UIImage], duration: TimeInterval) -> MSSticker? {
            guard let gifURL = createAnimatedGIF(with: images, duration: duration) else {
                return nil
            }
            
            do {
                let sticker = try MSSticker(contentsOfFileURL: gifURL, localizedDescription: "Animated Sticker")
                return sticker
            } catch {
                print("Failed to create sticker: \(error)")
                return nil
            }
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
            
            return temporaryFileURL
        }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func shareAction(_ sender: Any) {
        // image to share
////        let image = UIImage(named: "Image")
//        
//        // set up activity view controller
////        guard let data = try? Data(contentsOf: fileurl!) else {return}
//        let imageToShare = [ fileurl ]
//        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
//        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
//        
//        // exclude some activity types from the list (optional)
//        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
//        
//        // present the view controller
//        self.present(activityViewController, animated: true, completion: nil)
       
            let packName: String = "New pack" //pack["name"] as! String
            let packPublisher: String = "Mubin" //pack["publisher"] as! String
//            let packTrayImageFileName: String = pack["tray_image_file"] as! String

//            var packPublisherWebsite: String? = pack["publisher_website"] as? String
//            var packPrivacyPolicyWebsite: String? = pack["privacy_policy_website"] as? String
//            var packLicenseAgreementWebsite: String? = pack["license_agreement_website"] as? String
            // If the strings are empty, consider them as nil
//            packPublisherWebsite = packPublisherWebsite != "" ? packPublisherWebsite : nil
//            packPrivacyPolicyWebsite = packPrivacyPolicyWebsite != "" ? packPrivacyPolicyWebsite : nil
//            packLicenseAgreementWebsite = packLicenseAgreementWebsite != "" ? packLicenseAgreementWebsite : nil

            // Pack identifier has to be a valid string and be unique
            let packIdentifier: String? = UUID().uuidString // pack["identifier"] as? String
//            if packIdentifier != nil && currentIdentifiers[packIdentifier!] == nil {
//                currentIdentifiers[packIdentifier!] = true
//            } else {
//                if let packIdentifier = packIdentifier {
//                    fatalError("Missing identifier or a sticker pack already has the identifier \(packIdentifier).")
//                }
//
//                fatalError("\(packName) must have an identifier and it must be unique.")
//            }

//        let animatedStickerPack: Bool? = true //pack["animated_sticker_pack"] as? Bool

            var stickerPack: StickerPack?

            do {
                stickerPack = try StickerPack(identifier: packIdentifier!, name: packName, publisher: packPublisher, trayImageFileName: "tray_Cuppy", animatedStickerPack: isAnimated, publisherWebsite: nil, privacyPolicyWebsite: nil, licenseAgreementWebsite: nil)
                
                if isAnimated {
                    let data = retrieveDataFromDocumentsDirectory(filename: fileName)
                    stickerPack?.sendToWhatsApp(data: data, completionHandler: { isSend in
                        print(isSend)
                    })
                }else {
                    let img = ImageSaveRetrieveManager.shared.retrieveImageFromDocumentsFolder(imageName: fileName, foldername: ImageSaveRetrieveManager.imageStickersUrlFoldername)
                    guard let data = img?.pngData(), let upData = encode(pngData: data) else { return }
                    stickerPack?.sendToWhatsApp(data: upData, completionHandler: { isSend in
                        print(isSend)
                    })
                }
               
            }
//        catch StickerPackError.fileNotFound {
//                fatalError("\(packTrayImageFileName) not found.")
//            } catch StickerPackError.emptyString {
//                fatalError("The name, identifier, and publisher strings can't be empty.")
//            } catch StickerPackError.unsupportedImageFormat(let imageFormat) {
//                fatalError("\(packTrayImageFileName): \(imageFormat) is not a supported format.")
//            } catch StickerPackError.invalidImage {
//                fatalError("Tray image file size is 0 KB.")
//            } catch StickerPackError.imageTooBig(let imageFileSize, _) {
//                let roundedSize = round((Double(imageFileSize) / 1024) * 100) / 100;
//                fatalError("\(packTrayImageFileName): \(roundedSize) KB is bigger than the max tray image file size (\(Limits.MaxTrayImageFileSize / 1024) KB).")
//            } catch StickerPackError.incorrectImageSize(let imageDimensions) {
//                fatalError("\(packTrayImageFileName): \(imageDimensions) is not compliant with tray dimensions requirements, \(Limits.TrayImageDimensions).")
//            } catch StickerPackError.animatedImagesNotSupported {
//                fatalError("\(packTrayImageFileName) is an animated image. Animated images are not supported.")
//            } catch StickerPackError.stringTooLong {
//                fatalError("Name, identifier, and publisher of sticker pack must be less than \(Limits.MaxCharLimit128) characters.")
//            }
            catch {
                fatalError(error.localizedDescription)
            }

//            let stickers: [[String: Any]] = pack["stickers"] as! [[String: Any]]
//            for sticker in stickers {
//                let emojis: [String]? = sticker["emojis"] as? [String]
//
//                let filename = sticker["image_file"] as! String
//                do {
//                    try stickerPack!.addSticker(contentsOfFile: filename, emojis: emojis)
//                } catch StickerPackError.stickersNumOutsideAllowableRange {
//                    fatalError("Sticker count outside the allowable limit (\(Limits.MaxStickersPerPack) stickers per pack).")
//                } catch StickerPackError.fileNotFound {
//                    fatalError("\(filename) not found.")
//                } catch StickerPackError.unsupportedImageFormat(let imageFormat) {
//                    fatalError("\(filename): \(imageFormat) is not a supported format.")
//                } catch StickerPackError.invalidImage {
//                    fatalError("Image file size is 0 KB.")
//                } catch StickerPackError.imageTooBig(let imageFileSize, let animated) {
//                    let roundedSize = round((Double(imageFileSize) / 1024) * 100) / 100;
//                    let maxSize = animated ? Limits.MaxAnimatedStickerFileSize : Limits.MaxStaticStickerFileSize
//                    fatalError("\(filename): \(roundedSize) KB is bigger than the max file size (\(maxSize / 1024) KB).")
//                } catch StickerPackError.incorrectImageSize(let imageDimensions) {
//                    fatalError("\(filename): \(imageDimensions) is not compliant with sticker images dimensions, \(Limits.ImageDimensions).")
//                } catch StickerPackError.tooManyEmojis {
//                    fatalError("\(filename) has too many emojis. \(Limits.MaxEmojisCount) is the maximum number.")
//                } catch StickerPackError.minFrameDurationTooShort(let minFrameDuration) {
//                    let roundedDuration = round(minFrameDuration)
//                    fatalError("\(filename): \(roundedDuration) ms is shorter than the min frame duration (\(Limits.MinAnimatedStickerFrameDurationMS) ms).")
//                } catch StickerPackError.totalAnimationDurationTooLong(let totalFrameDuration) {
//                    let roundedDuration = round(totalFrameDuration)
//                    fatalError("\(filename): \(roundedDuration) ms is longer than the max total animation duration (\(Limits.MaxAnimatedStickerTotalDurationMS) ms).")
//                } catch StickerPackError.animatedStickerPackWithStaticStickers {
//                    fatalError("Animated sticker pack contains static stickers.")
//                } catch StickerPackError.staticStickerPackWithAnimatedStickers {
//                    fatalError("Static sticker pack contains animated stickers.")
//                } catch {
//                    fatalError(error.localizedDescription)
//                }
//            }
//
//            if stickers.count < Limits.MinStickersPerPack {
//              fatalError("Sticker count smaller that the allowable limit (\(Limits.MinStickersPerPack) stickers per pack).")
//            }
//
//            stickerPacks.append(stickerPack!)
    }
    
    func encode(pngData data: Data) -> Data? {
        guard let encoder = YYImageEncoder(type: YYImageType.webP) else { return nil }

        encoder.addImage(with: data, duration: 0.0)
        return encoder.encode()
    }
}

extension StickersViewController: MSStickerBrowserViewDataSource {
    func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        return stickers.count
    }

    func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
        return stickers[index]
    }
}
