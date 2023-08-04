//
//  Threshold.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/30.
//

import Foundation

extension ViewController {
    // 5フレーム前の距離の左右平均(defDepth)から次のフレームの閾値を決定
    func ikichiDecision(depth: Float) -> (faceMove: CGFloat, glanceMax: CGFloat, glanceMin: CGFloat, winkMax: Float, winkMin: Float, brink: Float) {
        
        // Face Move
        let faceMoveIkichiNext: CGFloat = faceMoveSliderValue
        
        // Eye Glance
        let glanceIkichiMinNext: CGFloat = 0.001 * CGFloat(depth) - glanceSliderValue
        let glanceIkichiMaxNext: CGFloat = -glanceIkichiMinNext * 0.92
        
        // wink
        winkIkichiMaxNext = -0.01242 * depth + Float(winkSliderValue)
        winkIkichiMinNext = -winkIkichiMaxNext * 0.96
        heightIkichiNext = -0.03 * depth + 23
        
        // brink
        brinkIkichNext = -winkIkichiMaxNext
        
        return(faceMoveIkichiNext, glanceIkichiMaxNext, glanceIkichiMinNext, winkIkichiMaxNext, winkIkichiMinNext, brinkIkichNext)
    }
}
