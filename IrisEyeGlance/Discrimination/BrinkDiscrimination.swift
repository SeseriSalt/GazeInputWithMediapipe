//
//  BrinkDiscrimination.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/27.
//

import Foundation

extension ViewController {
    func brinkDitect() -> Float {
        
        brinkIkichNext = winkIkichiMinNext
        let BRINK_IKICHI: Float = determinedIkichBrink
        
        if (brinkFlag == 0 && frameNum - distBrinkNum > 5 && leftEyelidDiff < BRINK_IKICHI && rightEyelidDiff < BRINK_IKICHI) {
            brinkFlag = 1
            brinkFirstPoint = frameNum
        }
        else if (brinkFlag == 1 && leftEyelidDiff > -BRINK_IKICHI && rightEyelidDiff > -BRINK_IKICHI && frameNum - brinkFirstPoint <= 4) {
            brinkFlag = 2
        }
        
        if (brinkFlag == 2) {
            brinkFlag = 0
            distBrinkNum = frameNum
            
            winkFlag = 0
            lateWinkFlag = 0
            maxDiff = 0
            minDiff = 0
            maxPeakFrameNum = 0
            minPeakFrameNum = 0
            peakPrev = 0
            peakNext = 0
            moveMissjudgeFlag = 0
            
            glanceFlag = 0
            glanceFirstPoint = 0
        }
        
        // 瞬きが失敗？した時の初期化
        if (brinkFlag != 0 && frameNum - brinkFirstPoint > 4) {
            brinkFlag = 0
        }
        return BRINK_IKICHI
    }
}
