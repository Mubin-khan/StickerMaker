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
        
        guard let imgData = cgImage.isPNG ? self.pngData() : self.jpegData(compressionQuality: 1) else { return nil }
        
        guard let source = CGImageSourceCreateWithData(imgData as CFData, sourceOptions) else { return nil }
        
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1920,
        ] as CFDictionary
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else { return nil }
        
        let data = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else { return nil }
        
        // Don't compress PNGs, they're too pretty
        let destinationProperties = [kCGImageDestinationLossyCompressionQuality: cgImage.isPNG ? 1.0 : 1] as CFDictionary
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

    func toCIImage() -> CIImage? {
        var ci = self.ciImage
        if ci == nil, let cg = self.cgImage {
            ci = CIImage(cgImage: cg)
        }
        return ci
    }
    
    func convertUIImageToCGImage() -> CGImage? {
        if let cgImage = self.cgImage {
            // Directly use the underlying CGImage if available
            return cgImage
        } else if let ciImage = self.ciImage {
            // Render the CIImage to a CGImage if the UIImage was backed by a CIImage
            let context = CIContext(options: nil)
            return context.createCGImage(ciImage, from: ciImage.extent)
        } else {
            // Render the UIImage to a CGImage if neither cgImage nor ciImage are available
            UIGraphicsBeginImageContext(self.size)
            self.draw(at: CGPoint.zero)
            let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return renderedImage?.cgImage
        }
    }
    
    func cropNonTransparent() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        guard let dataProvider = cgImage.dataProvider else { return nil }
        guard let pixelData = dataProvider.data else { return nil }
        guard let data = CFDataGetBytePtr(pixelData) else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let alphaInfo = cgImage.alphaInfo
        
        var minX = width
        var minY = height
        var maxX: Int = 0
        var maxY: Int = 0
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * bytesPerRow) + (x * bytesPerPixel)
                let alpha: UInt8
                
                switch alphaInfo {
                case .first, .premultipliedFirst:
                    alpha = data[pixelIndex]
                case .last, .premultipliedLast:
                    alpha = data[pixelIndex + 3]
                default:
                    continue
                }
                
                if alpha > 0 {
                    if x < minX { minX = x }
                    if y < minY { minY = y }
                    if x > maxX { maxX = x }
                    if y > maxY { maxY = y }
                }
            }
        }
        
        if minX >= maxX || minY >= maxY {
            // No non-transparent pixels found
            return nil
        }
        
        let cropRect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return nil }
        
        return UIImage(cgImage: croppedCgImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    func invertAlpha() -> UIImage? {
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let (width, height) = (Int(self.size.width), Int(self.size.height))
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let byteOffsetToAlpha = 3
        if let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                   space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue),
           let cgImage = self.cgImage {
            context.setFillColor(UIColor.clear.cgColor)
            context.fill(CGRect(origin: CGPoint.zero, size: self.size))
            context.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: self.size))
            if let memory: UnsafeMutableRawPointer = context.data {
                
                
                var y = 0
                while y<height {
                    let pointer = memory.advanced(by: bytesPerRow * y)
                    let buffer = pointer.bindMemory(to: UInt8.self, capacity: bytesPerRow)
                    
                    var x = 0
                    while x<width {
                        let rowOffset = x * bytesPerPixel + byteOffsetToAlpha
                        buffer[rowOffset] = 0xff - buffer[rowOffset]
                        x+=1
                    }
                    y+=1
                }
                
                if let cgImage =  context.makeImage() {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        return nil
    }
    
    func blurImage() -> UIImage? {
        guard let currCgImage = self.cgImage else {
            return nil
        }
        let currCiImage = CIImage(cgImage: currCgImage)
        
        let outputImage = currCiImage
            .applyingFilter("CIAffineClamp", parameters: [
                "inputTransform": CGAffineTransform.identity
            ]).applyingFilter("CIGaussianBlur", parameters: [
                "inputRadius": 40
            ])
        
        let context = CIContext()
        if let cgImg = context.createCGImage(outputImage, from: CGRect(origin: .zero, size: self.size)) {
            return UIImage(cgImage: cgImg)
        } else {
            return nil
        }
    }

}

extension UIImage {
    func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func resize(_ size: CGSize) -> UIImage? {
        if size.width <= 0 || size.height <= 0 {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        self.draw(in: CGRect(origin: .zero, size: size))
        let temp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return temp
    }
    
    func pixelateImage() -> UIImage? {
        guard let currCgImage = self.cgImage else {
            return nil
        }
        
        let scale = 8 * self.size.width / UIScreen.main.bounds.width
        let currCiImage = CIImage(cgImage: currCgImage)
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(currCiImage, forKey: kCIInputImageKey)
        filter?.setValue(scale, forKey: kCIInputScaleKey)
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        
        if let cgImg = context.createCGImage(outputImage, from: CGRect(origin: .zero, size: self.size)) {
            return UIImage(cgImage: cgImg)
        } else {
            return nil
        }
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
