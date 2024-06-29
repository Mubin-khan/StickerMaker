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
    
    func stroked(with color: UIColor = .white, thickness: CGFloat = 2, quality: CGFloat = 10) -> UIImage {
        
        guard let cgImage = cgImage else { return self }
        
        // Colorize the stroke image to reflect border color
        let strokeImage = colorized(with: color)
        
        guard let strokeCGImage = strokeImage.cgImage else { return self }
        
        /// Rendering quality of the stroke
        let step = quality == 0 ? 10 : abs(quality)
        
        let oldRect = CGRect(x: thickness, y: thickness, width: size.width, height: size.height).integral
        let newSize = CGSize(width: size.width + 2 * thickness, height: size.height + 2 * thickness)
        let translationVector = CGPoint(x: thickness, y: 0)
        
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        defer {
            UIGraphicsEndImageContext()
        }
        context.translateBy(x: 0, y: newSize.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.interpolationQuality = .high
        
        for angle: CGFloat in stride(from: 0, to: 360, by: step) {
            let vector = translationVector.rotated(around: .zero, byDegrees: angle)
            let transform = CGAffineTransform(translationX: vector.x, y: vector.y)
            
            context.concatenate(transform)
            
            context.draw(strokeCGImage, in: oldRect)
            
            let resetTransform = CGAffineTransform(translationX: -vector.x, y: -vector.y)
            context.concatenate(resetTransform)
        }
        
        context.draw(cgImage, in: oldRect)
        
        guard let stroked = UIGraphicsGetImageFromCurrentImageContext() else { return self }
        
        return stroked
    }
    
    func colorized(with color: UIColor = .white) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        defer {
            UIGraphicsEndImageContext()
        }

        guard let context = UIGraphicsGetCurrentContext(), let cgImage = cgImage else { return self }


        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        color.setFill()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.clip(to: rect, mask: cgImage)
        context.fill(rect)

        guard let colored = UIGraphicsGetImageFromCurrentImageContext() else { return self }

        return colored
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
