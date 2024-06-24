//
//  CustomTextLabel.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/25/24.
//

import UIKit

class CustomTextLabel: UILabel {
    var strokeColor: UIColor?
    var strokeLineWidth : CGFloat = 1
    
    override func drawText(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let strokeColor = strokeColor else {
            super.drawText(in: rect)
            return
        }

        let originalTextColor = self.textColor

        // Stroke
        context.setLineWidth(strokeLineWidth)
        context.setTextDrawingMode(.stroke)
        self.textColor = strokeColor
        super.drawText(in: rect)

        // Fill
        context.setLineWidth(0.0)
        context.setTextDrawingMode(.fill)
        self.textColor = originalTextColor
        super.drawText(in: rect)
    }
}
