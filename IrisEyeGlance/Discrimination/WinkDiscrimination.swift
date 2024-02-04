//
//  WinkDiscrimination.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/27.
//

import Foundation
import UIKit

var winkUpFlag = 0
var winkDownFlag = 0
var lateWinkFlag = 0
var moveMissjudgeFlag = 0
var maxDiff: Float = 0.0
var minDiff: Float = 0.0
var peakPrev: Float = 0.0
var peakNext: Float = 0.0
var winkMaxPeakFrame = 0
var winkMinPeakFrame = 0
var winkUpFirstFrame = 0
var winkDownFirstFrame = 0
var inputLabelFlag = 0
var distWinkNum = 0

var winkAreaUp: Float = 0.0
var winkAreaDown: Float = 0.0
var winkArrayAreaDown: [(frame: Int, area: Float, isUsed: Bool)] = [(frame: 0, area: 0, isUsed: false)]
var winkArrayAreaUp: [(frame: Int, area: Float, isUsed: Bool)] = [(frame: 0, area: 0, isUsed: false)]


extension ViewController {
    func winkDitect() -> (WINK_IKITCH_MAX: Float, WINK_IKITCH_MIN: Float) {
        // 判別に用いる閾値の決定
        let WINK_IKITCH_MAX: Float = winkIkichiMax
        let WINK_IKITCH_MIN: Float = winkIkichiMin
        let HEIGHT_DIFF_IKICHI: Float = winkIkichiHeight
        
        let WINK_IKITCH_AREAMAX: Float = winkIkichiMax * Float(winkAreaSliderValue)
        let WINK_IKITCH_AREAMIN: Float = winkIkichiMin * Float(winkAreaSliderValue)
        
        let frameLimit = frameNum - 15
        
        if (frameNum > 15 && frameNum - distWinkNum > 6 && frameNum - distBrinkNum > 6 && frameNum - distWinkInitNum > 5) {
            // 左目のWink判別
            if (winkUpFlag == 0 && lrDiff < WINK_IKITCH_MIN) {
                winkUpFlag = 1
                minDiff = lrDiff
                peakPrev = lrDiffPrev
                winkMinPeakFrame = frameNum
                winkUpFirstFrame = frameNum
                
                winkAreaUp += lrDiff
            }
            else if (winkUpFlag == 1 && lrDiff < minDiff) {
                minDiff = lrDiff
                peakPrev = lrDiffPrev
                winkMinPeakFrame = frameNum
                
                winkAreaUp += lrDiff
            }
            else if (winkUpFlag == 1 && lrDiff >= minDiff) {
                if (peakNext == 0.0) {
                    peakNext = lrDiff
                    
                    winkAreaUp += lrDiff
                }
                if (lrDiff > WINK_IKITCH_MIN) {
                    winkUpFlag = 2
                    peakPrev = 0
                    peakNext = 0
                    moveMissjudgeFlag = 0
                    
                    winkArrayAreaUp.insert((frame: winkUpFirstFrame, area: winkAreaUp, isUsed: false), at:0)
                    if winkAreaUp < WINK_IKITCH_AREAMIN {
                        // 15フレーム以内の要素をフィルタリングして新しい配列を作成する
                        let filteredArray = winkArrayAreaDown.filter { element in
                            if let frame = element.frame as? Int {
                                return frame >= frameLimit
                            }
                            return false
                        }
                        winkArrayAreaDown = filteredArray
                        // 新しい配列の要素に対して閾値判定
                        for i in 0..<winkArrayAreaDown.count {
                            if winkArrayAreaDown[i].area > WINK_IKITCH_AREAMAX && winkArrayAreaDown[i].isUsed == false {
                                winkUpFlag = 4
                                winkArrayAreaUp[0].isUsed = true
                                winkArrayAreaDown[i].isUsed = true
                                break
                            }
                        }
                    }
                    if winkUpFlag != 4 {
                        winkUpFlag = 0
                    }
                    winkUpFirstFrame = 0
                    winkAreaUp = 0
                    
                }
                else if (moveMissjudgeFlag == 0 && peakPrev * minDiff < 0 && peakNext * minDiff < 0) {
                    moveMissjudgeFlag = 1   // 他の動作による誤判別の検知
                }
            }
            
            // 右目のWink判別
            if (winkDownFlag == 0 && lrDiff > WINK_IKITCH_MAX) {
                winkDownFlag = -1
                maxDiff = lrDiff
                peakPrev = lrDiffPrev
                winkMaxPeakFrame = frameNum
                winkDownFirstFrame = frameNum
                
                winkAreaDown += lrDiff
            }
            else if (winkDownFlag == -1 && lrDiff > maxDiff) {
                maxDiff = lrDiff
                peakPrev = lrDiffPrev
                winkMaxPeakFrame = frameNum
                
                winkAreaDown += lrDiff
            }
            else if (winkDownFlag == -1 && lrDiff <= maxDiff) {
                if (peakNext == 0) {
                    peakNext = lrDiff
                    
                    winkAreaDown += lrDiff
                }
                
                if (lrDiff < WINK_IKITCH_MAX) {
                    winkDownFlag = -2
                    peakPrev = 0
                    peakNext = 0
                    moveMissjudgeFlag = 0
                    
                    winkArrayAreaDown.insert((frame: winkDownFirstFrame, area: winkAreaDown, isUsed: false), at:0)
                    if winkAreaDown > WINK_IKITCH_AREAMAX {
                        // 15フレーム以内の要素をフィルタリングして新しい配列を作成する
                        let filteredArray = winkArrayAreaUp.filter { element in
                            if let frame = element.frame as? Int {
                                return frame >= frameLimit
                            }
                            return false
                        }
                        winkArrayAreaUp = filteredArray
                        // 新しい配列の要素に対して閾値判定
                        for i in 0..<winkArrayAreaUp.count {
                            if winkArrayAreaUp[i].area < WINK_IKITCH_AREAMIN && winkArrayAreaUp[i].isUsed == false {
                                winkDownFlag = -4
                                winkArrayAreaDown[0].isUsed = true
                                winkArrayAreaUp[i].isUsed = true
                                break
                            }
                        }
                    }
                    if winkDownFlag != -4 {
                        winkDownFlag = 0
                    }
                    winkDownFirstFrame = 0
                    winkAreaDown = 0
                    
                }
                else if (moveMissjudgeFlag == 0 && peakPrev * maxDiff < 0 && peakNext * maxDiff < 0) {
                    moveMissjudgeFlag = 1   // 他の動作による誤判別の検知
                }
            }
        }
        
        // wink
        if (winkUpFlag == 4 || winkDownFlag == -4) {
            // ピーク感覚が5フレーム以上10フレーム以下の時、wink入力判定
//            if (abs(winkMaxPeakFrame - winkMinPeakFrame) >= 4 || lateWinkFlag == 1) {
                //                if (abs(maxPeakFrameNum - minPeakFrameNum) >= 5 && abs(maxPeakFrameNum - minPeakFrameNum) <= 10 || lateWinkFlag == 1) {
                inputLabelFlag = winkUpFlag == 4 ? 1 : 2
                let inputNumber = -inputLabelFlag
                DispatchQueue.main.async {
                    self.movementLabel.text = String(inputNumber)
                }
                inputResult = inputNumber
                distWinkNum = frameNum
                selectionDiscernment(vowelNumber: 0) //入力
                
                allInit()
            }
//        }
        
        // 他の動作による誤判別の場合の初期化
        if (moveMissjudgeFlag == 1) {
            winkInit()
        }
        
        // ピーク感覚が長すぎる時の初期化          多分違うからあとで切る
        if (winkUpFlag != 0 && frameNum - winkUpFirstFrame > 7) {
            moveMissjudgeFlag = 0
            winkInit()
        }
        // ピーク感覚が長すぎる時の初期化   あとで切る
        if (winkDownFlag != 0 && frameNum - winkDownFirstFrame > 7) {
            moveMissjudgeFlag = 0
            winkInit()
        }
        
        return(WINK_IKITCH_MAX, WINK_IKITCH_MIN)
    }
}
