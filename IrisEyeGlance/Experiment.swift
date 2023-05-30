//
//  Experiment.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/05/30.
//

import Foundation
import UIKit

//var questionList = ["あ", "か", "さ"]
var questionList = ["あ", "か","さ", "た", "な", "は", "ま", "や", "ら", "わ", "、。", "削除", "空白", "改行", "○"]

extension ViewController {
    func judgment() {
        DispatchQueue.main.async {
            if self.noseLabel.text == self.questionLabel.text {
                self.noseLabel.text = ""
                if questionList.isEmpty {// 全ての文字を表示し終わった場合
                    self.questionLabel.text = "終わり。"
                    self.questionLabel.textColor = UIColor.green
                }
                else {
                    self.questionLabel.text = self.getRandomLetter()
                }
            }
        }
    }
    
    // ランダムな文字を取得する関数
    func getRandomLetter() -> String? {
        guard !questionList.isEmpty else {
            return ""
        }
        
        let randomIndex = Int.random(in: 0..<questionList.count)
        let letter = questionList[randomIndex]
        questionList.remove(at: randomIndex)
        return letter
    }
    
    
}
