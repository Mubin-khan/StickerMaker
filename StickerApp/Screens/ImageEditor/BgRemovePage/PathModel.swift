//
//  PathModel.swift
//  Ereasy
//
//  Created by DSDEVMAC2 on 6/13/24.
//

import UIKit

public class ERPath: NSObject {
    let path: UIBezierPath
    let ratio: CGFloat
    var pathWidth : CGFloat
    let startPoint: CGPoint
    var blendMode : CGBlendMode
    var linePoints: [CGPoint] = []
    
    init(pathWidth: CGFloat, ratio: CGFloat, startPoint: CGPoint, blendMode : CGBlendMode) {
        path = UIBezierPath()
        path.lineWidth = pathWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: startPoint)
        
        self.pathWidth = pathWidth
        self.blendMode = blendMode
        self.ratio = ratio
        self.startPoint = CGPoint(x: startPoint.x / ratio, y: startPoint.y / ratio)
        
        super.init()
    }
    
    func addLine(to point: CGPoint, from oldPoint : CGPoint?) {
        if let oldPoint {path.move(to: oldPoint)}
//        path.addLine(to: point)
        linePoints.append(CGPoint(x: point.x / ratio, y: point.y / ratio))
    }
}

struct EraseRestoreModel : Equatable {
    var erPath : [ERPath]
}
