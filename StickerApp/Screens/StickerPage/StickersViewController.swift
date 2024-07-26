//
//  StickersViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/1/24.
//

import UIKit
import Messages
import MobileCoreServices
import SDWebImageWebPCoder
import Kingfisher


class StickersViewController: UIViewController {

   
    @IBOutlet weak var animatedImgVw: AnimatedImageView!
    @IBOutlet weak var stickerContainer: UIView!
    var stickers: [MSSticker] = []
    var gifUrl : URL?
    var imgUrl : URL?
    var fileurl : URL?
    
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
        
        if let fileurl {
//            guard let data = try? Data(contentsOf: fileurl) else {return}
            
            animatedImgVw.kf.setImage(with: fileurl)
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
//        let image = UIImage(named: "Image")
        
        // set up activity view controller
//        guard let data = try? Data(contentsOf: fileurl!) else {return}
        let imageToShare = [ fileurl! ]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
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
