//
//  Double+Extensions.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/28/24.
//

import Foundation

extension Double {
    func returnExpetedDurationString() -> String{
        let minutes = Int(self / 60)
        let seconds = Int(self) % 60
        let milliseconds = (self.truncatingRemainder(dividingBy: 1)) * 1000
        
        let miliString = String(milliseconds).prefix(1)
        
        return String(format: "%02d:%02d.\(miliString)", minutes, seconds)
    }
}
