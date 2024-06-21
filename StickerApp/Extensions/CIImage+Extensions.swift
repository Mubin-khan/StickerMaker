//
//  CIImage+Extensions.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/19/24.
//

import Foundation
import CoreImage

extension CIImage {
    func orientedUp() -> CIImage {
        // Check the current orientation of the CIImage
        let orientation = self.properties[kCGImagePropertyOrientation as String] as? Int ?? 1
        
        // Determine the appropriate transform for the current orientation
        var transform = CGAffineTransform.identity
        switch orientation {
        case 1:
            // .up, no transform needed
            transform = CGAffineTransform.identity
        case 2:
            // .upMirrored
            transform = CGAffineTransform(translationX: extent.width, y: 0).scaledBy(x: -1, y: 1)
        case 3:
            // .down
            transform = CGAffineTransform(translationX: extent.width, y: extent.height).rotated(by: .pi)
        case 4:
            // .downMirrored
            transform = CGAffineTransform(translationX: 0, y: extent.height).scaledBy(x: 1, y: -1)
        case 5:
            // .leftMirrored
            transform = CGAffineTransform(translationX: extent.width, y: 0).rotated(by: .pi / 2).scaledBy(x: -1, y: 1)
        case 6:
            // .right
            transform = CGAffineTransform(translationX: 0, y: extent.height).rotated(by: -.pi / 2)
        case 7:
            // .rightMirrored
            transform = CGAffineTransform(scaleX: -1, y: 1).rotated(by: -.pi / 2)
        case 8:
            // .left
            transform = CGAffineTransform(translationX: extent.width, y: extent.height).rotated(by: .pi / 2).scaledBy(x: -1, y: 1)
        default:
            // If the orientation is unknown, default to .up
            transform = CGAffineTransform.identity
        }
        
        // Apply the transform to the CIImage
        return self.transformed(by: transform)
    }
}
