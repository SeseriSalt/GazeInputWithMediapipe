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

var firstInput: Int = 1
var questionList = ["あ", "か","さ", "た", "な", "は", "ま", "や", "ら", "わ", "。?!", "削除", "空白", "改行", "○", "あ", "か","さ", "た", "な", "は", "ま", "や", "ら", "わ", "。?!", "削除", "空白", "改行", "○"]

var questionCharacter = "な"

extension ViewController {
    func judgment() {
        if inputCharacter == questionCharacter {
            DispatchQueue.main.async {
                self.inputLabel.text = ""
            }
            successTimer = Date().timeIntervalSince1970 - successTimerPrev
            successTimerPrev = Date().timeIntervalSince1970
            if firstInput == 1 {
                firstInput = 0
                inputCountCha = 0
                inputCountAll = 0
            }
            else {
                inputCountAll += inputCountCha
                printInputCountCha = inputCountCha
                inputCountCha = 0
            }
            if questionList.isEmpty {// 全ての文字を表示し終わった場合
                DispatchQueue.main.async {
                    self.questionLabel.text = "終わり。"
                    self.questionLabel.textColor = UIColor.green
                }
                judgeRatioAll = 30.0 / Double(inputCountAll)
            }
            else {
                getRandomLetter()
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
