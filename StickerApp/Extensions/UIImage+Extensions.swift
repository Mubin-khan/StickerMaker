//
//  UIImage+Extensions.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/18/24.
//

import UIKit
import CoreImage
import Accelerate
import MobileCoreServices
import UniformTypeIdentifiers


extension UIImage {
    func tint(with fillColor: UIColor) -> UIImage? {
        let image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        fillColor.set()
        image.draw(in: CGRect(origin: .zero, size: size))

        guard let imageColored = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }

        UIGraphicsEndImageContext()
        return imageColored
    }
    
    var asSmallImage: UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        
        guard let cgImage = self.cgImage else { return nil }
        
        guard let imgData = cgImage.isPNG ? self.pngData() : self.jpegData(compressionQuality: 0.75) else { return nil }
        
        guard let source = CGImageSourceCreateWithData(imgData as CFData, sourceOptions) else { return nil }
        
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 720,
        ] as CFDictionary
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else { return nil }
        
        let data = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else { return nil }
        
        // Don't compress PNGs, they're too pretty
        let destinationProperties = [kCGImageDestinationLossyCompressionQuality: cgImage.isPNG ? 1.0 : 0.75] as CFDictionary
        CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
        CGImageDestinationFinalize(imageDestination)
        
        let image = UIImage(data: data as Data)
        return image
    }
    
    func normalizeImageOrientation() -> UIImage {
       
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
    func cropImage(toRect cropRect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        // Perform the cropping
        guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return nil }

        // Create and return a UIImage from the cropped CGImage
        return UIImage(cgImage: croppedCgImage, scale: 1, orientation: .up)
    }
}


extension CGImage {
    
    /// Gives info whether or not this `CGImage` represents a png image
    /// By observing its UT type.
    var isPNG: Bool {
        if #available(iOS 14.0, *) {
            return (utType as String?) == UTType.png.identifier
        } else {
            return utType == kUTTypePNG
        }
    }
}
