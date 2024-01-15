//
//  EyeData.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/12/18.
//

import Foundation

class EyeData {
    var landmarks: [CGPoint] = [CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))]
    var refPoint = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    var irisPrev = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    var irisPrev2 = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    var refPointPrev = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    var refPointPrev2 = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    
    // 虹彩中心の差分値
    func irisDiff() -> CGPoint {
        let irisDiff = CGPoint(x: landmarks[0].x - irisPrev.x, y: landmarks[0].y - irisPrev.y)
        return irisDiff
    }
    
    func irisDiff2() -> CGPoint {
        let irisDiff2 = CGPoint(x: landmarks[0].x - irisPrev2.x, y: landmarks[0].y - irisPrev2.y)
        return irisDiff2
    }
    
    // フィルタ処理後の基準点の差分値
    func refPointDiff() -> CGPoint {
        let refPointDiff = CGPoint(x: refPoint.x - refPointPrev.x, y: refPoint.y - refPointPrev.y)
        return refPointDiff
    }
    
    func refPointDiff2() -> CGPoint {
        let refPointDiff2 = CGPoint(x: refPoint.x - refPointPrev2.x, y: refPoint.y - refPointPrev2.y)
        return refPointDiff2
    }
    
    // 目 - ローパス鼻の差分値
    func irisNoseDiff() -> CGPoint {
        let irisNoseDiff = CGPoint(x: self.irisDiff().x - self.refPointDiff().x, y: self.irisDiff().y - self.refPointDiff().y)
        return irisNoseDiff
    }
    
    func irisNoseDiff2() -> CGPoint {
        let irisNoseDiff2 = CGPoint(x: self.irisDiff2().x - self.refPointDiff2().x, y: self.irisDiff2().y - self.refPointDiff2().y)
        return irisNoseDiff2
    }
    
    func storeData() {
        self.irisPrev2 = irisPrev
        self.irisPrev = landmarks[0]
        self.refPointPrev2 = refPointPrev
        self.refPointPrev = refPoint
    }
}
