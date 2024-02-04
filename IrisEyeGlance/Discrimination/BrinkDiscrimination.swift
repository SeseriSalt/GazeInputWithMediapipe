//
//  BrinkDiscrimination.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/27.
//
import Foundation

var brinkFlag = 0
var brinkFirstFrame = 0
var distBrinkNum = 0

extension ViewController {
    func brinkDitect() -> Float {
        let BRINK_IKICHI: Float = brinkIkichi
        //brinkFlagが2というのは出力したい。出力後の次のフレームで0に初期化
        if(brinkFlag == 2){
            brinkFlag = 0
        }
        
        if (brinkFlag == 0 && frameNum - distBrinkNum > 5 && leftEyelidDiff < BRINK_IKICHI && rightEyelidDiff < BRINK_IKICHI) {
            brinkFlag = 1
            brinkFirstFrame = frameNum
        }
        
        else if (brinkFlag == 1 && leftEyelidDiff > -BRINK_IKICHI && rightEyelidDiff > -BRINK_IKICHI && frameNum - brinkFirstFrame <= 4) {
            brinkFlag = 2
        }
        
        if (brinkFlag == 2) {
            let inputNumber = 0
            DispatchQueue.main.async {
                self.movementLabel.text = String(inputNumber)
            }
            inputResult = inputNumber
            distBrinkNum = frameNum
//            allInit()
//            allInit関数からbrinkflag = 0を排除
            moveMissjudgeFlag = 0
            winkInit()
            
            glanceInit()
        }
        
        // 瞬きが失敗？(長すぎる)した時の初期化
        if (brinkFlag != 0 && frameNum - brinkFirstFrame > 8) {
            brinkFlag = 0
        }
        return BRINK_IKICHI
    }
}
