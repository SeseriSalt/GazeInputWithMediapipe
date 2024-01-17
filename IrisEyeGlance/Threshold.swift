//
//  Threshold.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/30.
//

import Foundation

extension ViewController {
    // 5フレーム前の距離の左右平均(defDepth)から次のフレームの閾値を決定
    func ikichiDecision(depth: Float) -> (glanceMaxBig: CGFloat, glanceMinBig: CGFloat, glanceMaxSmall: CGFloat, glanceMinSmall: CGFloat, areaUpBig: CGFloat, areaDownBig: CGFloat, areaUpSmall: CGFloat, areaDownSmall: CGFloat, winkMax: Float, winkMin: Float, brink: Float) {
        
        // Eye Glance
        //minの方が小さい
        let glanceIkichiMinSmallNext: CGFloat = 0.001 * CGFloat(depth) - glanceSliderValue
        let glanceIkichiMaxSmallNext: CGFloat = -glanceIkichiMinSmallNext * 0.92
        let glanceIkichiMaxBigNext: CGFloat = eyeGlanceThBig[0] * CGFloat(depth) / 10 + eyeGlanceThBig[1]
        let glanceIkichiMinBigNext: CGFloat = eyeGlanceThBig[2] * CGFloat(depth) / 10 + eyeGlanceThBig[3]
//        let glanceIkichiMaxSmallNext: CGFloat = eyeGlanceThSmall[0] * CGFloat(depth) / 10 + eyeGlanceThSmall[1]
//        let glanceIkichiMinSmallNext: CGFloat = eyeGlanceThSmall[2] * CGFloat(depth) / 10 + eyeGlanceThSmall[3]
        
        // 閾値を超えた時の面積の閾値
////        //上に凸な波形の面積計算用閾値
//        let ikichiAreaUpBig: CGFloat = glanceIkichiMaxSmallNext * 10.0
////        //下に凸な波形の面積計算用閾値
//        let ikichiAreaDownBig: CGFloat = glanceIkichiMinSmallNext * 10.0
//
        //        //上に凸な波形の面積計算用閾値
        let ikichiAreaUpSmall: CGFloat = glanceIkichiMaxSmallNext * 5.5
        //        //下に凸な波形の面積計算用閾値
        let ikichiAreaDownSmall: CGFloat = glanceIkichiMinSmallNext * 5.5
        let ikichiAreaUpBig: CGFloat = eyeGlanceThBig[4] * CGFloat(depth) / 10 + eyeGlanceThBig[5]
        let ikichiAreaDownBig: CGFloat = eyeGlanceThBig[6] * CGFloat(depth) / 10 + eyeGlanceThBig[7]
//        let ikichiAreaUpSmall: CGFloat = eyeGlanceThSmall[4] * CGFloat(depth) / 10 + eyeGlanceThSmall[5]
//        let ikichiAreaDownSmall: CGFloat = eyeGlanceThSmall[6] * CGFloat(depth) / 10 + eyeGlanceThSmall[7]
        
        // wink
        winkIkichiMaxNext = -0.01242 * depth + Float(winkSliderValue)
        winkIkichiMinNext = -winkIkichiMaxNext * 0.96
        heightIkichiNext = -0.03 * depth + 23
        
        // brink
        brinkIkichNext = -winkIkichiMaxNext
        
        return(glanceIkichiMaxBigNext, glanceIkichiMinBigNext, glanceIkichiMaxSmallNext, glanceIkichiMinSmallNext, ikichiAreaUpBig, ikichiAreaDownBig, ikichiAreaUpSmall, ikichiAreaDownSmall, winkIkichiMaxNext, winkIkichiMinNext, brinkIkichNext)
    }
}
