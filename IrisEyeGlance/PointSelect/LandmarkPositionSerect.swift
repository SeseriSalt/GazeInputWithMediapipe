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

let CHARACTER = [["あ", "い", "う", "え", "お"], ["か", "き", "く", "け", "こ"], ["さ", "し", "す", "せ", "そ"],["削除", "削除", "削除", "削除", "削除"], ["た", "ち", "つ", "て", "と"], ["な", "に", "ぬ", "ね", "の"], ["は", "ひ", "ふ", "へ", "ほ"], ["空白", "空白", "空白", "空白", "空白"], ["ま", "み", "む", "め", "も"], ["や", "ゆ", "ゆ", "よ", "よ"], ["ら", "り", "る", "れ", "ろ"], ["改行", "改行", "改行", "改行", "改行"], ["○", "○", "○", "○", "○"], ["わ", "を", "を", "ん", "ん"], ["、", "。", "？", "！", ""]]

extension ViewController {
   //ランドマークの位置で領域を選択する関数
    func LandmarkPositionSerect(point: CGPoint) -> Int {
        
        // 入力画面の中心座標・幅・高さを取得
        let inputScreen = getScreenInfo()
        
        //選択可能エリア
        let areaWidth = inputScreen.width //(max:390.0)
        let areaWidthCenter = inputScreen.center.x // 変更不要(defo: 195.0)
        let areaHeight = inputScreen.height  //(max:844.0)
        let areaHeightCenter = inputScreen.center.y //(avg:422.0)
        
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
        
        // 囲い線
        var lineRect = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(0.0), height: CGFloat(0.0))
        let RectWidth = abs(areaCol0 - areaCol1)
        let RectHeight0 = abs(areaRow0 - areaRow1)
        let RectHeight1 = abs(areaRow0 - areaRow2)
        //1段目
        if (point.x > areaCol0 && point.x < areaCol1 && point.y > areaRow0 && point.y < areaRow1) {
            lineRect = CGRect(x: areaCol0, y: areaRow0, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 1
        }
        else if (point.x > areaCol1 && point.x < areaCol2 && point.y > areaRow0 && point.y < areaRow1) {
            lineRect = CGRect(x: areaCol1, y: areaRow0, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 2
        }
        else if (point.x > areaCol2 && point.x < areaCol3 && point.y > areaRow0 && point.y < areaRow1) {
            lineRect = CGRect(x: areaCol2, y: areaRow0, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 3
        }
        else if (point.x > areaCol3 && point.x < areaCol4 && point.y > areaRow0 && point.y < areaRow1) {
            lineRect = CGRect(x: areaCol3, y: areaRow0, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 4
        }
        //2段目
        else if (point.x > areaCol0 && point.x < areaCol1 && point.y > areaRow1 && point.y < areaRow2) {
            lineRect = CGRect(x: areaCol0, y: areaRow1, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 5
        }
        else if (point.x > areaCol1 && point.x < areaCol2 && point.y > areaRow1 && point.y < areaRow2) {
            lineRect = CGRect(x: areaCol1, y: areaRow1, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 6
        }
        else if (point.x > areaCol2 && point.x < areaCol3 && point.y > areaRow1 && point.y < areaRow2) {
            lineRect = CGRect(x: areaCol2, y: areaRow1, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 7
        }
        else if (point.x > areaCol3 && point.x < areaCol4 && point.y > areaRow1 && point.y < areaRow2) {
            lineRect = CGRect(x: areaCol3, y: areaRow1, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 8
        }
        //3段目
        else if (point.x > areaCol0 && point.x < areaCol1 && point.y > areaRow2 && point.y < areaRow3) {
            lineRect = CGRect(x: areaCol0, y: areaRow2, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 9
        }
        else if (point.x > areaCol1 && point.x < areaCol2 && point.y > areaRow2 && point.y < areaRow3) {
            lineRect = CGRect(x: areaCol1, y: areaRow2, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 10
        }
        else if (point.x > areaCol2 && point.x < areaCol3 && point.y > areaRow2 && point.y < areaRow3) {
            lineRect = CGRect(x: areaCol2, y: areaRow2, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 11
        }
        else if (point.x > areaCol3 && point.x < areaCol4 && point.y > areaRow2 && point.y < areaRow4) {
            lineRect = CGRect(x: areaCol3, y: areaRow2, width: RectWidth, height: RectHeight1)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 12
        }
        //4段目
        else if (point.x > areaCol0 && point.x < areaCol1 && point.y > areaRow3 && point.y < areaRow4) {
            lineRect = CGRect(x: areaCol0, y: areaRow3, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 13
        }
        else if (point.x > areaCol1 && point.x < areaCol2 && point.y > areaRow3 && point.y < areaRow4) {
            lineRect = CGRect(x: areaCol1, y: areaRow3, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 14
        }
        else if (point.x > areaCol2 && point.x < areaCol3 && point.y > areaRow3 && point.y < areaRow4) {
            lineRect = CGRect(x: areaCol2, y: areaRow3, width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 15
        }
        else {
            DispatchQueue.main.async { [self] in
                if let oldRectLayer = self.rectLayer {
                    oldRectLayer.removeFromSuperlayer()
                }
            }
            changePositionFlag = 0
        }
        
        let areaChangeFlag = (changePositionFlag != prevChangePositionFlag) ? 1 : 0
        
        prevChangePositionFlag = changePositionFlag
        
        return areaChangeFlag
    }
    
    @objc func drawSelectionBorder(_ rectInfo: CGRect) {
        let rectPath = UIBezierPath(rect: rectInfo)
            
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = rectPath.cgPath
        shapeLayer.lineWidth = lineWidthList[tapCount]
        shapeLayer.strokeColor = UIColor(red: 26/255, green: 128/255, blue: 133/255, alpha: 1.0).cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        // すでに囲い線が描画されている場合、過去の線を削除
        if let oldRectLayer = rectLayer {
            oldRectLayer.removeFromSuperlayer()
        }
        
        view.layer.addSublayer(shapeLayer)
        
        rectLayer = shapeLayer
    }
    
    func selectionDiscernment(vowelNumber: Int) {
        // winkLabelの出力   →今viewControllerで使われてない
        if (frameNum - distBrinkNum <= 6) {
            DispatchQueue.main.async {
                self.lateFlagLabel.text = "brink"
                self.lateFlagLabel.textColor = UIColor.green
            }
        }
        else if (frameNum - distWinkNum <= 6) {    // これ違うくない？ 普通にframeNum = distFramenumでいんじゃね
            switch changePositionFlag {
            case 0:
                break
            default:
                DispatchQueue.main.async {
                    self.inputLabel.text = CHARACTER[changePositionFlag - 1][0]
                }
                inputCharacter = CHARACTER[changePositionFlag - 1][0]
                inputCountCha += 1
                if inputLabelFlag == 1 {
                    DispatchQueue.main.async {
                        self.inputLabel.textColor = UIColor.blue
                        self.questionLabel.textColor = UIColor.blue
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.inputLabel.textColor = UIColor.red
                        self.questionLabel.textColor = UIColor.red
                    }
                }
            }
        }
        else if (frameNum == distGlanceNum) {
            switch changePositionFlag {
            case 0:
                break
            default:
                DispatchQueue.main.async {
                    self.inputLabel.text = CHARACTER[changePositionFlag - 1][vowelNumber]
                }
                inputCharacter = CHARACTER[changePositionFlag - 1][vowelNumber]
                inputCountCha += 1
            }
        }
    }
}
