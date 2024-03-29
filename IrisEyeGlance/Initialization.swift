//
//  Initialization.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/28.
//

import Foundation
import UIKit

extension ViewController {
    func glanceInit() {
        glanceUpFlag = 0
        glanceDownFlag = 0
        glanceFirstFrame = 0
        countAreaUp = 0
        countAreaDown = 0
        directUp = 0
        directIrisUp = lrPoint(l: 0.0, r: 0.0)
        directDown = 0
        directIrisDown = lrPoint(l: 0.0, r: 0.0)
        glanceEndFrame = 0
        areaDown = 0
        areaUp = 0
    }
    
    func winkInit() {
        winkUpFlag = 0
        winkDownFlag = 0
        lateWinkFlag = 0
        maxDiff = 0
        minDiff = 0
        winkMaxPeakFrame = 0
        winkMinPeakFrame = 0
        peakPrev = 0
        peakNext = 0
        // winkFirstFrame = 0
        winkAreaUp = 0
        winkAreaDown = 0
    }
    
    func allInit() {
        brinkFlag = 0
        ikichiAreaUp = 0
        ikichiAreaDown = 0
        moveMissjudgeFlag = 0
        winkInit()
        glanceInit()
    }
    
    func inputInit() {
        inputCountAll = 0
        judgeRatioAll = 0.0
        
        inputCountCha = 0
        printInputCountCha = 0
        
        firstInputFlag = 1
//        questionList = ["あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ", "さ", "し", "す", "せ", "そ","削除", "た", "ち", "つ", "て", "と", "な", "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "空白", "ま", "み", "む", "め", "も", "や", "ゆ", "よ", "ら", "り", "る", "れ", "ろ", "改行", "わ", "を", "ん", "、", "。", "？", "！"]
        questionList = ["a", "b", "c", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u"]
        
        questionCharacter = "a"
        DispatchQueue.main.async {
            self.inputLabel.text = ""
            self.questionLabel.text = "a"
            self.questionLabel.textColor = UIColor.black
            self.resultLabel.text = ""
        }
    }
}
