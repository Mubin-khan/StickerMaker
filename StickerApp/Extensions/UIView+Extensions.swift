//
//  UIView+Extensions.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/1/24.
//

import UIKit

extension UIView {
    
    func toImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    func to512x512Image(size: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        // Create a container view of fixed 512x512 size
        let containerView = UIView(frame: CGRect(origin: .zero, size: size))
        containerView.backgroundColor = .clear  // Transparent background if desired
        
        // Center the view within the container view
        let scale = min(size.width / bounds.width, size.height / bounds.height)
        let scaledWidth = bounds.width * scale
        let scaledHeight = bounds.height * scale
        self.frame = CGRect(x: (size.width - scaledWidth) / 2,
                            y: (size.height - scaledHeight) / 2,
                            width: scaledWidth,
                            height: scaledHeight)
        
        // Add the scaled view to the container
        containerView.addSubview(self)
        
        // Render the container view to a UIImage
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { rendererContext in
            containerView.layer.render(in: rendererContext.cgContext)
        }
        
        // Convert the image to PNG format and return
        return image.pngData().flatMap { UIImage(data: $0) }
    }

   
}
