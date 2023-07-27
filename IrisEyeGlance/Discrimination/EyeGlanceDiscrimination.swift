//
//  EyeGlanceDiscrimination.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/24.
//

import Foundation

extension ViewController {
    func eyeGlanceDitect(leftY: CGFloat, rightY: CGFloat, leftX: CGFloat, rightX: CGFloat) -> (glanceDist: CGFloat, directionDist: CGFloat) {
        
        //判別波形
        let glanceDist = (leftY + rightY) / 2 * 800
        let directionDist = leftX * rightX * 100000
        
        // eye glance判別の閾値 上方向と下方向の移動で分ける
        let glanceIkichiUp: CGFloat = glanceUpSliderValue
        let glanceIkichiDown: CGFloat = glanceDownSliderValue
        
        // eye glance判別開始
        if (frameNum > 15 && frameNum - distGlanceNum > 6 && frameNum - distBrinkNum > 6 && frameNum - distWinkNum > 6 && frameNum - distInitNum > 5) {
            if (glanceFlag == 0 && glanceDist < glanceIkichiUp) {
                glanceFlag = 1
                glanceFirstPoint = frameNum
            }
            else if (glanceFlag == 1 && glanceDist > glanceIkichiUp) {
                glanceFlag = 2
            }
            else if (glanceFlag == 2 && glanceDist > glanceIkichiDown) {
                glanceFlag = 3
            }
            else if (glanceFlag == 3 && glanceDist < glanceIkichiDown) {
                glanceFlag = 4
            }
            else if (glanceFlag == 0 && glanceDist > glanceIkichiDown) {
                glanceFlag = -1
                glanceFirstPoint = frameNum
            }
            else if (glanceFlag == -1 && glanceDist < glanceIkichiDown) {
                glanceFlag = -2
            }
            else if (glanceFlag == -2 && glanceDist < glanceIkichiUp) {
                glanceFlag = -3
            }
            else if (glanceFlag == -3 && glanceDist > glanceIkichiUp) {
                glanceFlag = -4
            }
        }
        
        // x方向決めのための値取得
        if (glanceFlag == 1 || glanceFlag == -1) {
            if (firstDirect < directionDist) {
                firstDirect = directionDist
                firstDirectIris = lrPoint(l: leftX, r: rightX)
            }
        }
        else if (glanceFlag == 3 || glanceFlag == -3) {
            if (secondDirect < directionDist) {
                secondDirect = directionDist
                secondDirectIris = lrPoint(l: leftX, r: rightX)
            }
        }
        
        //glance判別関数
        func updateGlanceLabel(glanceDirection: Int, glanceSymbol1: Int, glanceSymbol2: Int) {
            if (glanceFlag == glanceDirection && frameNum - glanceFirstPoint > 5) {
                var vowelNumber: Int
                
                if (firstDirect > secondDirect) {
                    if ((abs(firstDirectIris.l) > abs(firstDirectIris.r) ? firstDirectIris.l : firstDirectIris.r) < 0.0) {
                        vowelNumber = glanceSymbol1
                    }
                    else {
                        vowelNumber = glanceSymbol2
                    }
                }
                else {
                    if ((abs(secondDirectIris.l) > abs(secondDirectIris.r) ? secondDirectIris.l : secondDirectIris.r) > 0.0) {
                        vowelNumber = glanceSymbol1
                    }
                    else {
                        vowelNumber = glanceSymbol2
                    }
                }
                
                // メインスレッドでラベルのテキストを更新
                DispatchQueue.main.async {
                    self.movementLabel.text = String(vowelNumber)
                }
                glanceResult = vowelNumber
                
                distGlanceNum = frameNum
                selectionDiscernment(vowelNumber: vowelNumber) // 入力
                glanceFlag = 0
                glanceFirstPoint = 0
                firstDirect = 0.0
                firstDirectIris = lrPoint(l: 0.0, r: 0.0)
                secondDirect = 0.0
                secondDirectIris = lrPoint(l: 0.0, r: 0.0)
            }
        }
        
        // 呼び出し
        updateGlanceLabel(glanceDirection: 4, glanceSymbol1: 1, glanceSymbol2: 2)
        updateGlanceLabel(glanceDirection: -4, glanceSymbol1: 3, glanceSymbol2: 4)
        
        //短すぎるeye glance初期化
        if ((glanceFlag == 4 || glanceFlag == -4) && frameNum - glanceFirstPoint <= 5) {
            distInitNum = frameNum
            glanceFlag = 0
            glanceFirstPoint = 0
            firstDirect = 0.0
            firstDirectIris = lrPoint(l: 0.0, r: 0.0)
            secondDirect = 0.0
            secondDirectIris = lrPoint(l: 0.0, r: 0.0)
        }
        
        //長すぎるeye glance初期化
        if (glanceFlag != 0 && frameNum - glanceFirstPoint > 15) {
            glanceFlag = 0
            glanceFirstPoint = 0
            firstDirect = 0.0
            firstDirectIris = lrPoint(l: 0.0, r: 0.0)
            secondDirect = 0.0
            secondDirectIris = lrPoint(l: 0.0, r: 0.0)
        }
        return(glanceDist, directionDist)
    }
}



//  Eye Glance指標の残骸置いとく
//            let x_ave = (leftIrisDiff_x + rightIrisDiff_x) / 2
//
//            // 横の基準点（鼻）の正規化
//            let normalizedValue = (landmarkAll[5][0] - minValue) / (maxValue - minValue)
//            let refPoint = CGPoint(x: CGFloat(normalizedValue), y: CGFloat(landmarkAll[5][1]))
//            // 基準点のdiff
//            let refPointDiff = refPoint.x - refPointPrev.x
//            // 虹彩中心から基準点の距離
//            let relativeDiffLeft_x = normalizedLeftIris[0].x - CGFloat(refPoint.x)
//            let relativeDiffRight_x = normalizedRightIris[0].x - CGFloat(refPoint.x)
//            // 虹彩中心から基準点の距離のdiff
//            relativeDistance_x = lrPoint(l: relativeDiffLeft_x, r: relativeDiffRight_x)
//            let relativeDistanceLeftDiff = relativeDistance_x.l - relativeDistance_xPrev.l
//            let relativeDistanceRightDiff = relativeDistance_x.r - relativeDistance_xPrev.r
//            // 目頭・目尻のランドマークx正規化
//            let leftInnerPoint = (landmarkAll[133][0] - minValue) / (maxValue - minValue)
//            let leftOuterPoint = (landmarkAll[33][0] - minValue) / (maxValue - minValue)
//
//            let rightInnerPoint = (landmarkAll[362][0] - minValue) / (maxValue - minValue)
//            let rightOuterPoint = (landmarkAll[263][0] - minValue) / (maxValue - minValue)
//            // 目頭と虹彩内側、目尻と虹彩外側の距離
//            let leftInnerWhite = CGFloat(leftInnerPoint) * CGFloat(screenWidth) - normalizedLeftIris[1].x * CGFloat(screenWidth)
//            let leftOuterWhite = normalizedLeftIris[3].x * CGFloat(screenWidth) - CGFloat(leftOuterPoint) * CGFloat(screenWidth)
//
//            let rightInnerWhite = normalizedRightIris[1].x * CGFloat(screenWidth) - CGFloat(rightInnerPoint) * CGFloat(screenWidth)
//            let rightOuterWhite = CGFloat(rightOuterPoint) * CGFloat(screenWidth) - normalizedRightIris[3].x * CGFloat(screenWidth)
//            // 目頭・目尻の距離のdiff
//            let leftInnerWhiteDiff = leftInnerWhite - leftInnerWhitePrev
//            let leftOuterWhiteDiff = leftOuterWhite - leftOuterWhitePrev
//
//            let rightInnerWhiteDiff = rightInnerWhite - rightInnerWhitePrev
//            let rightOuterWhiteDiff = rightOuterWhite - rightOuterWhitePrev




//            print(frameNum, normalizedLeftIris[0].x, normalizedLeftIris[0].y, normalizedLeftIris[1].x, normalizedLeftIris[1].y, normalizedLeftIris[2].x, normalizedLeftIris[2].y, normalizedLeftIris[3].x, normalizedLeftIris[3].y, normalizedLeftIris[4].x, normalizedLeftIris[4].y, normalizedRightIris[0].x, normalizedRightIris[0].y, normalizedRightIris[1].x, normalizedRightIris[1].y, normalizedRightIris[2].x, normalizedRightIris[2].y, normalizedRightIris[3].x, normalizedRightIris[3].y, normalizedRightIris[4].x, normalizedRightIris[4].y, leftInnerPoint, leftOuterPoint, rightInnerPoint, rightOuterPoint)


// ↓ここから下：次のフレームで使用する現在の値を保存・初期化

//            relativeDistance_xPrev = relativeDistance_x
//            refPointPrev = refPoint
//
//            leftInnerWhitePrev = leftInnerWhite
//            leftOuterWhitePrev = leftOuterWhite
//            rightInnerWhitePrev = rightInnerWhite
//            rightOuterWhitePrev = rightOuterWhite
