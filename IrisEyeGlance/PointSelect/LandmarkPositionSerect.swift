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
        
        // 囲い線
        var lineRect = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(0.0), height:(0.0))
        let RectWidth = CGFloat(len(a: areaCol0, b: areaCol1))
        let RectHeight0 = CGFloat(len(a: areaRow0, b: areaRow1))
        let RectHeight1 = CGFloat(len(a: areaRow0, b: areaRow2))
        //1段目
        if (xPoint > areaCol0 && xPoint < areaCol1 && yPoint > areaRow0 && yPoint < areaRow1) {
            lineRect = CGRect(x: CGFloat(areaCol0), y: CGFloat(areaRow0), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 1
        }
        else if (xPoint > areaCol1 && xPoint < areaCol2 && yPoint > areaRow0 && yPoint < areaRow1) {
            lineRect = CGRect(x: CGFloat(areaCol1), y: CGFloat(areaRow0), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 2
        }
        else if (xPoint > areaCol2 && xPoint < areaCol3 && yPoint > areaRow0 && yPoint < areaRow1) {
            lineRect = CGRect(x: CGFloat(areaCol2), y: CGFloat(areaRow0), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 3
        }
        else if (xPoint > areaCol3 && xPoint < areaCol4 && yPoint > areaRow0 && yPoint < areaRow1) {
            lineRect = CGRect(x: CGFloat(areaCol3), y: CGFloat(areaRow0), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 4
        }
        //2段目
        else if (xPoint > areaCol0 && xPoint < areaCol1 && yPoint > areaRow1 && yPoint < areaRow2) {
            lineRect = CGRect(x: CGFloat(areaCol0), y: CGFloat(areaRow1), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 5
        }
        else if (xPoint > areaCol1 && xPoint < areaCol2 && yPoint > areaRow1 && yPoint < areaRow2) {
            lineRect = CGRect(x: CGFloat(areaCol1), y: CGFloat(areaRow1), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 6
        }
        else if (xPoint > areaCol2 && xPoint < areaCol3 && yPoint > areaRow1 && yPoint < areaRow2) {
            lineRect = CGRect(x: CGFloat(areaCol2), y: CGFloat(areaRow1), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 7
        }
        else if (xPoint > areaCol3 && xPoint < areaCol4 && yPoint > areaRow1 && yPoint < areaRow2) {
            lineRect = CGRect(x: CGFloat(areaCol3), y: CGFloat(areaRow1), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 8
        }
        //3段目
        else if (xPoint > areaCol0 && xPoint < areaCol1 && yPoint > areaRow2 && yPoint < areaRow3) {
            lineRect = CGRect(x: CGFloat(areaCol0), y: CGFloat(areaRow2), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 9
        }
        else if (xPoint > areaCol1 && xPoint < areaCol2 && yPoint > areaRow2 && yPoint < areaRow3) {
            lineRect = CGRect(x: CGFloat(areaCol1), y: CGFloat(areaRow2), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 10
        }
        else if (xPoint > areaCol2 && xPoint < areaCol3 && yPoint > areaRow2 && yPoint < areaRow3) {
            lineRect = CGRect(x: CGFloat(areaCol2), y: CGFloat(areaRow2), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 11
        }
        else if (xPoint > areaCol3 && xPoint < areaCol4 && yPoint > areaRow2 && yPoint < areaRow4) {
            lineRect = CGRect(x: CGFloat(areaCol3), y: CGFloat(areaRow2), width: RectWidth, height: RectHeight1)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 12
        }
        //4段目
        else if (xPoint > areaCol0 && xPoint < areaCol1 && yPoint > areaRow3 && yPoint < areaRow4) {
            lineRect = CGRect(x: CGFloat(areaCol0), y: CGFloat(areaRow3), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 13
        }
        else if (xPoint > areaCol1 && xPoint < areaCol2 && yPoint > areaRow3 && yPoint < areaRow4) {
            lineRect = CGRect(x: CGFloat(areaCol1), y: CGFloat(areaRow3), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 14
        }
        else if (xPoint > areaCol2 && xPoint < areaCol3 && yPoint > areaRow3 && yPoint < areaRow4) {
            lineRect = CGRect(x: CGFloat(areaCol2), y: CGFloat(areaRow3), width: RectWidth, height: RectHeight0)
            DispatchQueue.main.async {
                self.drawSelectionBorder(lineRect)
            }
            changePositionFlag = 15
        }
        else {
            DispatchQueue.main.async { [self] in
                self.noseLabel.text = "0"
                if let oldRectLayer = self.rectLayer {
                    oldRectLayer.removeFromSuperlayer()
                }
            }
            changePositionFlag = 0
        }
        
        let areaChangeFlag = (changePositionFlag != prevChangePositionFlag) ? 1 : 0
        
        prevChangePositionFlag = changePositionFlag
//        print(prevChangePositionFlag)
        
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
    
    func len(a: Float, b: Float) -> Float {
        let c = fabsf(b - a)
        return c
    }
    
    func selectionDiscernment() {
        // winkLabelの出力
        if (frameNum - brinkFrameNum <= 6) {
             // 瞬き　何もしない
        }
        else if (frameNum - distFrameNum <= 6) {
            switch changePositionFlag {
            case 1:
                DispatchQueue.main.async {
                    self.noseLabel.text = "あ"
                }
            case 2:
                DispatchQueue.main.async {
                    self.noseLabel.text = "か"
                }
            case 3:
                DispatchQueue.main.async {
                    self.noseLabel.text = "さ"
                }
            case 4:
                DispatchQueue.main.async {
                    self.noseLabel.text = "Del"
                }
            case 5:
                DispatchQueue.main.async {
                    self.noseLabel.text = "た"
                }
            case 6:
                DispatchQueue.main.async {
                    self.noseLabel.text = "な"
                }
            case 7:
                DispatchQueue.main.async {
                    self.noseLabel.text = "は"
                }
            case 8:
                DispatchQueue.main.async {
                    self.noseLabel.text = "[　]"
                }
            case 9:
                DispatchQueue.main.async {
                    self.noseLabel.text = "ま"
                }
            case 10:
                DispatchQueue.main.async {
                    self.noseLabel.text = "や"
                }
            case 11:
                DispatchQueue.main.async {
                    self.noseLabel.text = "ら"
                }
            case 12:
                DispatchQueue.main.async {
                    self.noseLabel.text = "↩︎"
                }
            case 13:
                DispatchQueue.main.async {
                    self.noseLabel.text = "○"
                }
            case 14:
                DispatchQueue.main.async {
                    self.noseLabel.text = "わ"
                }
            case 15:
                DispatchQueue.main.async {
                    self.noseLabel.text = "、。"
                }
            default:
                print(1)
            }
            
            if changePositionFlag != 0 {
                if labelFlag == 1 {
                    DispatchQueue.main.async {
                        self.noseLabel.textColor = UIColor.blue
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.noseLabel.textColor = UIColor.red
                    }
                }
            }
        }
        else {
                // 何もしない？
        }
    }
}
