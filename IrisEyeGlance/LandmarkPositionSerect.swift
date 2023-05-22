//
//  LandmarkPositionSerect.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/05/22.
//

import Foundation
import UIKit

public var changePositionFlag = 0
public var prevChangePositionFlag = 0

extension ViewController {
   //ランドマークの位置で領域を選択する関数
    func LandmarkPositionSerect(_ xPoint: Float, _ yPoint: Float) -> Int {
        
        // 入力画面の中心座標・幅・高さを取得
        let inputScreen = getScreenInfo()
        
        //選択可能エリア
        let areaWidth: Float = Float(inputScreen.width) //(max:390.0)
        let areaWidthCenter: Float = Float(inputScreen.center.x) // 変更不要(defo: 195.0)
        let areaHeight: Float = Float(inputScreen.height)  //(max:844.0)
        let areaHeightCenter: Float = Float(inputScreen.center.y) //(avg:422.0)
        
        //縦線
        let areaCol0 = areaWidthCenter - areaWidth / 2
        let areaCol1 = areaWidthCenter - areaWidth / 4
        let areaCol2 = areaWidthCenter //真ん中
        let areaCol3 = areaWidthCenter + areaWidth / 4
        let areaCol4 = areaWidthCenter + areaWidth / 2
        //横線
        let areaRow0 = areaHeightCenter - areaHeight / 2
        let areaRow1 = areaHeightCenter - areaHeight / 4
        let areaRow2 = areaHeightCenter //真ん中
        let areaRow3 = areaHeightCenter + areaHeight / 4
        let areaRow4 = areaHeightCenter + areaHeight / 2
        
        //1段目
        if (xPoint > areaCol0 && xPoint < areaCol1 && yPoint > areaRow0 && yPoint < areaRow1) {
            DispatchQueue.main.async {
                self.noseLabel.text = "1"
            }
            changePositionFlag = 1
        }
        else if (xPoint > areaCol1 && xPoint < areaCol2 && yPoint > areaRow0 && yPoint < areaRow1) {
            DispatchQueue.main.async {
                self.noseLabel.text = "2"
            }
            changePositionFlag = 2
        }
        else if (xPoint > areaCol2 && xPoint < areaCol3 && yPoint > areaRow0 && yPoint < areaRow1) {
            DispatchQueue.main.async {
                self.noseLabel.text = "3"
            }
            changePositionFlag = 3
        }
        else if (xPoint > areaCol3 && xPoint < areaCol4 && yPoint > areaRow0 && yPoint < areaRow1) {
            DispatchQueue.main.async {
                self.noseLabel.text = "4"
            }
            changePositionFlag = 4
        }
        //中部
        else if (xPoint > areaCol0 && xPoint < areaCol1 && yPoint > areaRow1 && yPoint < areaRow2) {
            DispatchQueue.main.async {
                self.noseLabel.text = "5"
            }
            changePositionFlag = 5
        }
        else if (xPoint > areaCol1 && xPoint < areaCol2 && yPoint > areaRow1 && yPoint < areaRow2) {
            DispatchQueue.main.async {
                self.noseLabel.text = "6"
            }
            changePositionFlag = 6
        }
        else if (xPoint > areaCol2 && xPoint < areaCol3 && yPoint > areaRow1 && yPoint < areaRow2) {
            DispatchQueue.main.async {
                self.noseLabel.text = "7"
            }
            changePositionFlag = 7
        }
        else if (xPoint > areaCol3 && xPoint < areaCol4 && yPoint > areaRow1 && yPoint < areaRow2) {
            DispatchQueue.main.async {
                self.noseLabel.text = "8"
            }
            changePositionFlag = 8
        }
        //3段目
        else if (xPoint > areaCol0 && xPoint < areaCol1 && yPoint > areaRow2 && yPoint < areaRow3) {
            DispatchQueue.main.async {
                self.noseLabel.text = "9"
            }
            changePositionFlag = 9
        }
        else if (xPoint > areaCol1 && xPoint < areaCol2 && yPoint > areaRow2 && yPoint < areaRow3) {
            DispatchQueue.main.async {
                self.noseLabel.text = "10"
            }
            changePositionFlag = 10
        }
        else if (xPoint > areaCol2 && xPoint < areaCol3 && yPoint > areaRow2 && yPoint < areaRow3) {
            DispatchQueue.main.async {
                self.noseLabel.text = "11"
            }
            changePositionFlag = 11
        }
        else if (xPoint > areaCol3 && xPoint < areaCol4 && yPoint > areaRow2 && yPoint < areaRow4) {
            DispatchQueue.main.async {
                self.noseLabel.text = "12"
            }
            changePositionFlag = 12
        }
        //4段目
        else if (xPoint > areaCol0 && xPoint < areaCol1 && yPoint > areaRow3 && yPoint < areaRow4) {
            DispatchQueue.main.async {
                self.noseLabel.text = "13"
            }
            changePositionFlag = 13
        }
        else if (xPoint > areaCol1 && xPoint < areaCol2 && yPoint > areaRow3 && yPoint < areaRow4) {
            DispatchQueue.main.async {
                self.noseLabel.text = "14"
            }
            changePositionFlag = 14
        }
        else if (xPoint > areaCol2 && xPoint < areaCol3 && yPoint > areaRow3 && yPoint < areaRow4) {
            DispatchQueue.main.async {
                self.noseLabel.text = "15"
            }
            changePositionFlag = 15
        }
        else {
            DispatchQueue.main.async {
                self.noseLabel.text = "0"
            }
            changePositionFlag = 0
        }
        
        let areaChangeFlag = (changePositionFlag != prevChangePositionFlag) ? 1 : 0
        
        prevChangePositionFlag = changePositionFlag
//        print(prevChangePositionFlag)
        
        return areaChangeFlag
    }

}
