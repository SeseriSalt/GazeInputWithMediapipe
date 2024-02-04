//
//  Threshold.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/30.
//

import Foundation

extension ViewController {
    // 5フレーム前の距離の左右平均(defDepth)から次のフレームの閾値を決定
    func ikichiDecision(depth: Float) -> (glanceMax: CGFloat, glanceMin: CGFloat, glanceAreaUp: CGFloat, glanceAreaDown: CGFloat, winkMax: Float, winkMin: Float, brink: Float) {
        
        // Eye Glance
        //minの方が小さい
        let glanceIkichiMinNext: CGFloat = 0.001 * CGFloat(depth) - glanceSliderValue
        let glanceIkichiMaxNext: CGFloat = -glanceIkichiMinNext
        
        // 閾値を超えた時の面積の閾値
        //        //上に凸な波形の面積計算用閾値
        let ikichiAreaUp: CGFloat = glanceIkichiMaxNext * integralSliderValue
        //        //下に凸な波形の面積計算用閾値
        let ikichiAreaDown: CGFloat = glanceIkichiMinNext * integralSliderValue
        
        // wink
        winkIkichiMaxNext = /*-0.01242*/ -0.011 * depth + Float(winkSliderValue)
        winkIkichiMinNext = -winkIkichiMaxNext * 0.96
        heightIkichiNext = -0.03 * depth + 23
        
        // brink
        brinkIkichNext = -winkIkichiMaxNext - 2.0
        
        return(glanceIkichiMaxNext, glanceIkichiMinNext, ikichiAreaUp, ikichiAreaDown, winkIkichiMaxNext, winkIkichiMinNext, brinkIkichNext)
    }
}
