//
//  NormalizedLandmark.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/25.
//

import Foundation

// x軸正規化の最小値・最大値
public let NORMALIZED_CONST: (min: CGFloat, max: CGFloat) = (min: 0.08978804, max: 0.9095595)

extension ViewController {
    
    // 1点のランドマークを正規化するための関数
    func normalizedLandmarkPoint(point: [Float]) -> CGPoint {
        let normalizedX = (CGFloat(point[0]) - NORMALIZED_CONST.min) / (NORMALIZED_CONST.max - NORMALIZED_CONST.min)
        let refPoint = CGPoint(x: CGFloat(normalizedX), y: CGFloat(point[1]))
        return refPoint
    }
    
    // 虹彩のランドマークを正規化するための関数
    func normalizeLandmarks(_ landmarks: [[Float]]) -> [CGPoint] {
        var normalizedIris: [CGPoint] = []
        for landmark in landmarks {
            let normalizedValue = (CGFloat(landmark[0]) - NORMALIZED_CONST.min) / (NORMALIZED_CONST.max - NORMALIZED_CONST.min)
            normalizedIris.append(CGPoint(x: CGFloat(normalizedValue), y: CGFloat(landmark[1])))
        }
        return normalizedIris
    }
}
