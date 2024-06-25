//
//  CustomTextLabel.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/25/24.
//

//import UIKit
//
//class CustomTextLabel: UILabel {
//    var strokeColor: UIColor?
//    var strokeLineWidth : CGFloat = 1
//    
//    override func drawText(in rect: CGRect) {
//        guard let context = UIGraphicsGetCurrentContext(), let strokeColor = strokeColor else {
//            super.drawText(in: rect)
//            return
//        }
//
//        let originalTextColor = self.textColor
//
//        // Stroke
//        context.setLineWidth(strokeLineWidth)
//        context.setTextDrawingMode(.stroke)
//        self.textColor = strokeColor
//        super.drawText(in: rect)
//
//        // Fill
//        context.setLineWidth(0.0)
//        context.setTextDrawingMode(.fill)
//        self.textColor = originalTextColor
//        super.drawText(in: rect)
//    }
//}

import UIKit

class CustomTextLabel: UILabel {
    var strokeColor: UIColor?
    var strokeLineWidth: CGFloat = 1
    var characterSpacing: CGFloat = 1.5

    override func drawText(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let strokeColor = strokeColor else {
            super.drawText(in: rect)
            return
        }

        guard let text = self.text else {
            super.drawText(in: rect)
            return
        }

        // Create attributed string with character spacing
        let attributedString = NSAttributedString(string: text, attributes: [
            .kern: characterSpacing,
            .foregroundColor: self.textColor ?? UIColor.black
        ])

        // Stroke
        context.setLineWidth(strokeLineWidth)
        context.setTextDrawingMode(.stroke)
        let strokeAttributedString = NSAttributedString(string: text, attributes: [
            .kern: characterSpacing,
            .foregroundColor: strokeColor
        ])
        self.attributedText = strokeAttributedString
        super.drawText(in: rect)

        // Fill
        context.setLineWidth(0.0)
        context.setTextDrawingMode(.fill)
        self.attributedText = attributedString
        super.drawText(in: rect)
    }
}

