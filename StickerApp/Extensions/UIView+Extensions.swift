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
   
}
