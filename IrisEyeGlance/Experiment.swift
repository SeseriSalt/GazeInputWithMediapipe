//
//  Experiment.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/05/30.
//

import Foundation
import UIKit

var successTimer = Date().timeIntervalSince1970
var successTimerPrev = Date().timeIntervalSince1970

var inputCountAll: Int = 0
var judgeRatioAll: Double = 0.0

var inputCountCha: Int = 0
var printInputCountCha: Int = 0

var firstInputFlag: Int = 1
//var questionList = ["あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ", "さ", "し", "す", "せ", "そ","削除", "た", "ち", "つ", "て", "と", "な", "に", "ぬ", "ね", "の", "は", "ひ", "ふ", "へ", "ほ", "空白", "ま", "み", "む", "め", "も", "や", "ゆ", "よ", "ら", "り", "る", "れ", "ろ", "改行", "わ", "を", "ん", "、", "。", "？", "！"]
var questionList = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
var questionListCount: Int = 0

var questionCharacter = "a"

extension ViewController {
    func judgment() {
        if inputCharacter == questionCharacter {
            DispatchQueue.main.async {
                self.inputLabel.text = ""
            }
            successTimer = Date().timeIntervalSince1970 - successTimerPrev
            successTimerPrev = Date().timeIntervalSince1970
            if firstInputFlag == 1 {
                firstInputFlag = 0
                inputCountCha = 0
                inputCountAll = 0
            }
            else {
                inputCountAll += inputCountCha
                printInputCountCha = inputCountCha
                inputCountCha = 0
            }
            if questionList.isEmpty {// 全ての文字を表示し終わった場合
                judgeRatioAll = 26.0 / Double(inputCountAll)
                DispatchQueue.main.async {
                    self.questionLabel.text = "終わり。"
                    self.questionLabel.textColor = UIColor.green
                    self.resultLabel.text = String(format: "%.1f", judgeRatioAll * 100) + "%"
                }
            }
            else {
                getRandomLetter()
                questionListCount += 1
            }
        }
    }
    
    // ランダムな文字を取得する関数
    func getRandomLetter() {
        let randomIndex = Int.random(in: 0..<questionList.count)
        let letter = questionList[randomIndex]
        questionList.remove(at: randomIndex)
        DispatchQueue.main.async {
            self.questionLabel.text = letter
        }
        questionCharacter = letter
    }
    
    
}
