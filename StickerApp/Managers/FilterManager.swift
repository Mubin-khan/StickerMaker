//
//  FilterManager.swift
//  StickerApp
//
//  Created by Mubin Khan on 6/30/24.
//

import UIKit
import CoreImage
import Accelerate
import simd

public typealias SMFilterApplierType = ((_ image: UIImage) -> UIImage)

@objc public enum SMFilterType: Int {
    case normal
    case chrome
    case fade
    case instant
    case process
    case transfer
    case tone
    case linear
    case sepia
    case mono
    case noir
    case tonal
    case xray
    case vignette
    case enhance
    case falseColor
    
        
    var coreImageFilterName: String {
        switch self {
        case .normal:
            return ""
        case .chrome:
            return "CIPhotoEffectChrome"
        case .fade:
            return "CIPhotoEffectFade"
        case .instant:
            return "CIPhotoEffectInstant"
        case .process:
            return "CIPhotoEffectProcess"
        case .transfer:
            return "CIPhotoEffectTransfer"
        case .tone:
            return "CILinearToSRGBToneCurve"
        case .linear:
            return "CISRGBToneCurveToLinear"
        case .sepia:
            return "CISepiaTone"
        case .mono:
            return "CIPhotoEffectMono"
        case .noir:
            return "CIPhotoEffectNoir"
        case .tonal:
            return "CIPhotoEffectTonal"
        case .xray:
            return "CIXRay"
        case .vignette:
            return "CIVignette"
        case .enhance:
            return "CIDocumentEnhancer"
        case .falseColor:
            return "CIFalseColor"
        }
    }
}

public class SMFilter: NSObject {
    
   
    public var name: String
    
    let applier: SMFilterApplierType?
    
    @objc public init(name: String, filterType: SMFilterType) {
        self.name = name
        
        if filterType != .normal {
            self.applier = { image -> UIImage in
                guard let ciImage = image.toCIImage() else {
                    return image
                }

                let filter = CIFilter(name: filterType.coreImageFilterName)
                filter?.setValue(ciImage, forKey: kCIInputImageKey)
                guard let outputImage = filter?.outputImage?.toUIImage() else {
                    return image
                }
                return outputImage
            }
        } else {
            self.applier = nil
        }
    }
    
    /// 可传入 applier 自定义滤镜
    @objc public init(name: String, applier: SMFilterApplierType?) {
        self.name = name
        self.applier = applier
    }
    
}

extension SMFilter {
    @objc public static let normal = SMFilter(name: "None", filterType: .normal)
    @objc public static let chrome = SMFilter(name: "Chrome", filterType: .chrome)
    @objc public static let fade = SMFilter(name: "Fade", filterType: .fade)
    @objc public static let instant = SMFilter(name: "Instant", filterType: .instant)
    @objc public static let process = SMFilter(name: "Process", filterType: .process)
    @objc public static let transfer = SMFilter(name: "Transfer", filterType: .transfer)
    @objc public static let tone = SMFilter(name: "Tone", filterType: .tone)
    @objc public static let linear = SMFilter(name: "Linear", filterType: .linear)
    @objc public static let sepia = SMFilter(name: "Sepia", filterType: .sepia)
    @objc public static let mono = SMFilter(name: "Mono", filterType: .mono)
    @objc public static let noir = SMFilter(name: "Noir", filterType: .noir)
    @objc public static let tonal = SMFilter(name: "Tonal", filterType: .tonal)
    @objc public static let xray = SMFilter(name: "Xray", filterType: .xray)
    @objc public static let vignette = SMFilter(name: "Vignette", filterType: .vignette)
    @objc public static let enhance = SMFilter(name: "Enhance", filterType: .enhance)
    @objc public static let falseColor = SMFilter(name: "FalseColor", filterType: .falseColor)
}


extension SMFilter {
    @objc public static let ciFilters: [SMFilter] = [.normal, .chrome, .fade, .instant, .process, .vignette, .transfer, .tone, .linear, .sepia, .mono, .noir, .tonal, .xray, vignette, .enhance, .falseColor]
}

