//
//  HomeViewController.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/18/24.
//

import UIKit
import PhotosUI
import AVFoundation

class HomeViewController: UIViewController, PHPickerViewControllerDelegate {
   
    var frames : [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        frames.removeAll()
    }
    
    @IBAction func getLivePhotoAction(_ sender: Any) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .livePhotos
        configuration.selectionLimit = 1
        
        presentPicker(with: configuration)
    }
    
    @IBAction func getVideoAction(_ sender: Any) {
        PHPhotoLibrary.requestAuthorization({
            (newStatus) in
            if newStatus ==  PHAuthorizationStatus.authorized {
                var configuration = PHPickerConfiguration()
                configuration.filter = .videos
                configuration.selectionLimit = 1
                
                self.presentPicker(with: configuration)
            }
        })
        
       
    }
    
    @IBAction func textToStickerAction(_ sender: Any) {
        let vc = TextInputViewController()
        vc.modalPresentationStyle = .overFullScreen
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func openCameraAction(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
               imagePickerController.delegate = self
               imagePickerController.sourceType = .camera
               imagePickerController.allowsEditing = false
               present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func getGifAction(_ sender: Any) {
        if !NetWorkManager.shared.isNetworkReachable() {
            showError(title: "Error!", message: "No Internet! Please check your network connectivity.")
            return
        }
        let vc = GifViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func showError(title : String, message : String){
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    @IBAction func getPhotoAction(_ sender: Any) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        presentPicker(with: configuration)
    }
    
    private func presentPicker(with config : PHPickerConfiguration) {
        DispatchQueue.main.async {
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        for result in results {
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: PHLivePhoto.self) {
                provider.loadObject(ofClass: PHLivePhoto.self) { (livePhoto, error) in
                    if let livePhoto = livePhoto as? PHLivePhoto {
                        self.handleLivePhoto(livePhoto)
                    }
                }
            }
            
            else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { (url, error) in
                            guard let url = url else {
                                if let error = error {
                                    print("Error loading file representation: \(error.localizedDescription)")
                                }
                                return
                            }

                            // Move the file to a temporary location to access it
                            let tempDirectory = FileManager.default.temporaryDirectory
                            let tempURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")

                            do {
                                try FileManager.default.moveItem(at: url, to: tempURL)
                                DispatchQueue.main.async {
//                                    self.extractFramesFromVideo(at: tempURL)
                                    self.gotoEditPage(with: tempURL)
                                }
                            } catch {
                                print("Error moving file: \(error.localizedDescription)")
                            }
                        }
            }
            else if provider.canLoadObject(ofClass: UIImage.self) {
                let prov = result.itemProvider
                prov.loadObject(ofClass: UIImage.self) { im, err in
                    if let img = im as? UIImage {
                        DispatchQueue.main.async {
                            let mainImage = img.asSmallImage ?? img
                            self.gotoCropViewController(with: mainImage)
                        }
                    }
                }
           }
        }
    }
    
    func gotoCropViewController(with img : UIImage) {
        let vc = CropperViewController(originalImage: img)
        let navVC = UINavigationController(rootViewController: vc)
        navVC.isNavigationBarHidden = true
        navVC.modalPresentationStyle = .fullScreen
        self.present(navVC, animated: true, completion: nil)
    }
    
    func extractFramesFromVideo(at url: URL, frameCount: Int = 10) {
        let asset = AVAsset(url: url)
        let assetDuration = CMTimeGetSeconds(asset.duration)
        let times = stride(from: 0, to: assetDuration, by: assetDuration / Double(frameCount - 1)).map {
            CMTimeMakeWithSeconds($0, preferredTimescale: asset.duration.timescale)
        }
        
        extractFrames(at: times, from: asset)
    }

    func extractFrames(at times: [CMTime], from asset: AVAsset) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let dispatchGroup = DispatchGroup()

        for time in times {
            dispatchGroup.enter()
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
                if let cgImage = cgImage {
                    let uiImage = UIImage(cgImage: cgImage)
                    self.frames.append(uiImage.normalizeImageOrientation())
                } else if let error = error {
                    print("Error generating image: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
//            self.gotoEditPage()
        }
    }
    
    func handleLivePhoto(_ livePhoto: PHLivePhoto) {
        // This is where you'll extract frames from the live photo
        extractFrames(from: livePhoto)
    }
    
    func extractFrames(from livePhoto: PHLivePhoto) {
        guard let assetResource = PHAssetResource.assetResources(for: livePhoto).first(where: { $0.type == .pairedVideo }) else { return }
        
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let videoURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        
        PHAssetResourceManager.default().writeData(for: assetResource, toFile: videoURL, options: options) { error in
            if let error = error {
                print("Error writing video data: \(error.localizedDescription)")
                return
            }
            
            self.gotoEditPage(with: videoURL)
//            self.extractFramesFromLivePhoto(at: videoURL)
        }
    }

    func extractFramesFromLivePhoto(at url: URL) {
        let asset = AVAsset(url: url)
        let assetReader = try! AVAssetReader(asset: asset)
        let videoTrack = asset.tracks(withMediaType: .video).first!
        
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let assetReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        assetReader.add(assetReaderOutput)
        assetReader.startReading()
        
        print("\(videoTrack.preferredTransform) okk")
        
        while let sampleBuffer = assetReaderOutput.copyNextSampleBuffer() {
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                // Adjust the CIImage orientation
                               let orientedCIImage = ciImage.oriented(forExifOrientation: videoTrack.preferredTransform.exifOrientation)
                               let uiImage = UIImage(ciImage: orientedCIImage)
                               frames.append(uiImage)
            }
        }
        
//        gotoEditPage()
    }
    
    private func gotoEditPage(with url : URL){
        DispatchQueue.main.async {
//            let vc = EditViewController(frames: self.frames)
            let vc = IntermediateViewController(url: url)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension HomeViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // Delegate method to handle the photo taken
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true, completion: nil)
            if let image = info[.originalImage] as? UIImage, let finalImage = image.asSmallImage {
                self.gotoCropViewController(with: finalImage)
            }
        }
        
        // Delegate method to handle cancellation
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
        }
}


// Helper function to convert CGAffineTransform to EXIF orientation
extension CGAffineTransform {
    var exifOrientation: Int32 {
        switch (a, b, c, d) {
        case (1, 0, 0, 1):
            return 1 // .up
        case (-1, 0, 0, -1):
            return 3 // .down
        case (0, 1, -1, 0):
            return 6 // .right
        case (0, -1, 1, 0):
            return 8 // .left
        case (1, 0, 0, -1):
            return 2 // .upMirrored
        case (-1, 0, 0, 1):
            return 4 // .downMirrored
        case (0, 1, 1, 0):
            return 5 // .leftMirrored
        case (0, -1, -1, 0):
            return 7 // .rightMirrored
        default:
            return 1 // Default to .up
        }
    }
}


public enum GifFeatue {
    case text
    case livePhoto
    case video
    case gif
    case image
}
