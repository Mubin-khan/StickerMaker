//
//  CGSize+Extensions.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/18/24.
//

import Foundation

extension CGSize {
    
    func calculateFinalSize(in availableSize: CGSize) -> CGSize {
        let widthRatio = availableSize.width / self.width
        let heightRatio = availableSize.height / self.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let finalWidth = self.width * scaleFactor
        let finalHeight = self.height * scaleFactor
        
        return CGSize(width: finalWidth, height: finalHeight)
    }
    
}
