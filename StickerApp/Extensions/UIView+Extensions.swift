//
//  UIView+Extensions.swift
//  StickerApp
//
//  Created by Mubin Khan on 7/1/24.
//

import UIKit

extension UIView {
    
    func toImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
   
}
