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
        glanceFlag = 0
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
        glanceUpPrev = 0.0
        glanceDownPrev = 0.0
        glanceUpPeak = 0.0
        glanceDownPeak = 0.0
        glanceUpNext = 100.0
        glanceDownNext = -100.0
    }
    
    func winkInit() {
        winkFlag = 0
        lateWinkFlag = 0
        maxDiff = 0
        minDiff = 0
        winkMaxPeakFrame = 0
        winkMinPeakFrame = 0
        peakPrev = 0
        peakNext = 0
    }
    
    func allInit() {
        brinkFlag = 0
        ikichiAreaUpBig = 0
        ikichiAreaDownBig = 0
        ikichiAreaUpSmall = 0
        ikichiAreaDownSmall = 0
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
        questionList = ["あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ", "さ", "し", "す", "せ", "そ","削除", "た", "ち", "つ", "て", "と", "な", "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "空白", "ま", "み", "む", "め", "も", "や", "ゆ", "よ", "ら", "り", "る", "れ", "ろ", "改行", "わ", "を", "ん", "、", "。", "？", "！"]
        //var questionList = ["あ", "い", "う", "え", "お"]
        
        questionCharacter = "な"
        DispatchQueue.main.async {
            self.questionLabel.text = "な"
            self.questionLabel.textColor = UIColor.black
        }
    }
}
