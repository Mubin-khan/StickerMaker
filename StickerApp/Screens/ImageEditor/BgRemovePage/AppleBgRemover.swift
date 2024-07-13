//
//  AppleBgRemover.swift
//  Ereasy
//
//  Created by DSDEVMAC2 on 6/12/24.
//

import UIKit
import Vision
import Accelerate
import CoreML

final class AppleBgRemover {
    
    static let shared = AppleBgRemover()
    private init(){}
    
    private lazy var personSegmentationRequest: VNGeneratePersonSegmentationRequest = {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        return request
    }()
    
    func applyPersonSegmentation(ciImage : CIImage) -> CIImage? {
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
                       
        try? requestHandler.perform([personSegmentationRequest])
        guard let resultPixelBuffer = personSegmentationRequest.results?.first?.pixelBuffer else { return nil}

        let isPersonAvailable = isPersonDetected(in: resultPixelBuffer)
        return isPersonAvailable ? CIImage(cvPixelBuffer: resultPixelBuffer) : nil
    }
    
    private func isPersonDetected(in pixelBuffer: CVPixelBuffer) -> Bool {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return false
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        let threshold: UInt8 = 50 // Adjust threshold as needed
        var detected = false
        
        for y in 0..<height {
            let row = baseAddress.advanced(by: y * bytesPerRow)
            for x in 0..<width {
                let pixel = row.load(fromByteOffset: x, as: UInt8.self)
                if pixel > threshold {
                    print(pixel)
                    detected = true
                    break
                }
            }
            if detected {
                break
            }
        }
        
        return detected
    }
}
