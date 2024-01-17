//
//  EyeGlanceDiscrimination.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/24.
//

import Foundation

extension ViewController {
    func eyeGlance(left: CGPoint, right: CGPoint, refDiff: CGPoint, ikichi: (maxBig: CGFloat, minBig: CGFloat, maxSmall: CGFloat, minSmall: CGFloat, areaupBig: CGFloat, areadownBig: CGFloat, areaupSmall: CGFloat, areadownSmall: CGFloat)) -> (glanceDist: CGFloat, directionDist: CGFloat, correctionValue: CGFloat) {
            //left, rightには左目と右目の1点差分のデータが入ってる(x, y座標が入ってる)
            //注意！！！！英瑠は左目と右目の平均を取ってから差分を取っていたが、ヤダさんは左目と右目でそれぞれ1点差分を取ってから左目と右目の平均を取っている
            // 鼻部の移動に対してかかる補正値
            let correctionValue = CGFloat(pow(0.8865681506, Double(abs(refDiff.y)) * 1000))
            // Eye Glance判別波形
            let glanceDist = (left.y + right.y) / 2 * 800 * /*correctionValue*/1
            let directionDist = left.x * right.x * 100000
            
            // Eye Glance判別
            if (frameNum > 15 && frameNum - distGlanceNum > 6 && frameNum - areaChangeFrame > 6 && frameNum - distBrinkNum > 6 && frameNum - distWinkNum > 6 && frameNum - distGlanceInitNum > 5) {
                eyeGlanceDitect(glanceDist: glanceDist, directionDist: directionDist, xPoint: lrPoint(l: left.x, r: right.x), ikichi: (maxBig: ikichi.maxBig, minBig: ikichi.minBig, maxSmall: ikichi.maxSmall, minSmall: ikichi.minSmall, areaupBig: ikichi.areaupBig, areadownBig: ikichi.areadownBig, areaupSmall: ikichi.areaupSmall, areadownSmall: ikichi.areadownSmall))
            }
            else{
                glanceInit()
            }
            return(glanceDist, directionDist, correctionValue)
        }
    
    func eyeGlanceDitect(glanceDist: CGFloat, directionDist: CGFloat, xPoint: lrPoint, ikichi: (maxBig: CGFloat, minBig: CGFloat, maxSmall: CGFloat, minSmall: CGFloat, areaupBig: CGFloat, areadownBig: CGFloat, areaupSmall: CGFloat, areadownSmall: CGFloat)) {
        
        //　xpoint(lrPoint)は左目xの差分値と右目xの差分値が入ってる
                // eye glance判別の閾値 上方向と下方向の移動で分ける
                //ikichi: (max: glanceIkichiMax, min: glanceIkichiMin, face: faceMoveIkichi).ikichidecesionでこう定義されている
                //glanceIkichiUpは目が上を向いた時(波形的には下向き)の時に使われるものと予想。だから、ikichiUPの方がikichiDownより小さい！！！
        //        let glanceIkichiUpBig: CGFloat = ikichi.minBig
        //        let glanceIkichiDownBig: CGFloat = ikichi.maxBig
        let glanceIkichiUpSmall: CGFloat = ikichi.minSmall
        let glanceIkichiDownSmall: CGFloat = ikichi.maxSmall
        
        let frameLimit = frameNum - 20
        
        // eye glance判別開始
        // 目が上を見た時(波形的には下向き)
        if (glanceFlag == 0 && glanceDist < glanceIkichiUpSmall) {
            glanceFlag = 1
            glanceFirstPoint = frameNum
            //yの閾値超える1つ前のフレームと，とりあえずのピーク
            glanceDownPrev = glanceDistPrev
            glanceDownPeak = glanceDist
            // とりあえずxのピーク
            directDown = directionDist
            directIrisDown = xPoint
            areaDown += glanceDist
            countAreaDown += 1
            endFrame = frameNum
        }
        else if (glanceFlag == 1 && glanceDist < 0.0) {
            areaDown += (glanceIkichiUpSmall - glanceDist) * glanceDist //
            countAreaDown += 1
            endFrame = frameNum
            // yのピーク更新
            glanceDownPeak = glanceDownPeak > glanceDist ? glanceDist : glanceDownPeak
            // xのピーク更新
            if (directDown < directionDist) {
                directDown = directionDist
                directIrisDown = xPoint
                //directIrisDownには左目xと右目xの差分値が入ってる
            }
        }
        if (glanceFlag == 1 && glanceDist > glanceIkichiUpSmall && glanceDownNext < glanceDownPeak) {
            glanceDownNext = glanceDist
        }
        else if (glanceFlag == 1 && glanceDist > 0.0) {
            glanceFlag = 2
            arrayAreaDown.insert((frame: endFrame, area: areaDown, prev: glanceDownPrev, peak: glanceDownPeak, next: glanceDownNext, direct_d: directDown, direct_i: directIrisDown, isUsed: false), at:0)
            if areaDown < ikichi.areadownSmall {
                // 20フレーム以内の要素をフィルタリングして新しい配列を作成する
                let filteredArray = arrayAreaUp.filter { element in
                    if let frame = element.frame as? Int {
                        return frame >= frameLimit
                    }
                    return false
                }
                arrayAreaUp = filteredArray
                // 新しい配列の要素に対して閾値判定
                for i in 0..<arrayAreaUp.count {
                    if arrayAreaUp[i].area > ikichi.areaupSmall /*&& arrayAreaUp[i].peak - arrayAreaUp[i].prev > 0.9 && arrayAreaUp[i].peak - arrayAreaUp[i].next > 0.9*/ && arrayAreaUp[i].isUsed == false{
                        glanceFlag = -4
                        arrayAreaDown[0].isUsed = true
                        arrayAreaUp[i].isUsed = true
                        directUp = arrayAreaUp[i].direct_d
                        directIrisUp = arrayAreaUp[i].direct_i
                        break
                    }
                }
            }
            if glanceFlag != -4 {
                glanceFlag = 0
                directDown = 0
                directIrisDown = lrPoint(l:0.0, r:0.0)
            }
            endFrame = 0
            areaDown = 0
            glanceDownNext = -100.0
        }
        // 目が下を見た時(波形的には上向き)
        else if (glanceFlag == 0 && glanceDist > glanceIkichiDownSmall) {
            glanceFlag = -1
            glanceFirstPoint = frameNum
            glanceUpPrev = glanceDistPrev
            glanceUpPeak = glanceDist
            directUp = directionDist
            directIrisUp = xPoint
            areaUp += glanceDist
            countAreaUp += 1
            endFrame = frameNum
        }
        else if (glanceFlag == -1 && glanceDist > 0.0) {
            areaUp += (glanceDist - glanceIkichiDownSmall) * glanceDist
            countAreaUp += 1
            endFrame = frameNum
            // yのピーク更新
            glanceUpPeak = glanceUpPeak < glanceDist ? glanceDist : glanceUpPeak
            // xのピーク更新
            if (directUp < directionDist) {
                directUp = directionDist
                directIrisUp = xPoint
                //directIrisDownには左目xと右目xの差分値が入ってる
            }
        }
        if (glanceFlag == -1 && glanceDist < glanceIkichiDownSmall && glanceUpNext > glanceUpPeak) {
            glanceUpNext = glanceDist
        }
        else if(glanceFlag == -1 && glanceDist < 0.0) {
            glanceFlag = -2
            arrayAreaUp.insert((frame: endFrame, area: areaUp, prev: glanceUpPrev, peak: glanceUpPeak, next: glanceUpNext, direct_d: directUp, direct_i: directIrisUp, isUsed: false), at:0)
            if areaUp > ikichi.areaupBig {
                // 20フレーム以内の要素をフィルタリングして新しい配列を作成する
                let filteredArray = arrayAreaDown.filter { element in
                    if let frame = element.frame as? Int {
                        return frame >= frameLimit
                    }
                    return false
                }
                arrayAreaDown = filteredArray
                // 新しい配列の要素に対して閾値判定
                for i in 0..<arrayAreaDown.count {
                    if arrayAreaDown[i].area < ikichi.areadownBig /*&& arrayAreaDown[i].prev - arrayAreaDown[i].peak > 1.5 && arrayAreaDown[i].next - arrayAreaDown[i].peak > 1.5 */&& arrayAreaDown[i].isUsed == false{
                        glanceFlag = 4
                        arrayAreaUp[0].isUsed = true
                        arrayAreaDown[i].isUsed = true
                        directDown = arrayAreaDown[i].direct_d
                        directIrisDown = arrayAreaDown[i].direct_i
                        break
                    }
                }
            }
            if glanceFlag != 4{
                glanceFlag = 0
                directUp = 0
                directIrisUp = lrPoint(l:0.0, r:0.0)
            }
            endFrame = 0
            areaUp = 0
            glanceUpNext = 100.0
        }
        
        //glance判別関数
               func updateGlanceLabel(glanceDirection: Int, glanceSymbol1: Int, glanceSymbol2: Int) {
                   //glanceflgaには今とれた上か下かの方向(4 or -4)が入っている
                   if (glanceFlag == glanceDirection) {
                       var inputNumber: Int
                       if (glanceFlag == -4) {
                           //一つ目のピーク時のxの掛け算と2つ目のピーク時のxの掛け算の大きい方(EyeGlance波形におけるxの掛け算は必ず正のため)で見る(大きい方が信頼できるから)
                           if (directUp > directDown) {
                               //lとrで絶対値が大きい方が選ばれ(左目と右目なので単純に大きい方が信頼できるから)、それが0未満なら以下の処理。そうでないならelse。
                               if (abs(directIrisUp.l) > abs(directIrisUp.r) ? directIrisUp.l : directIrisUp.r) < 0.0 {
                                   //おそらく左
                                   inputNumber = glanceSymbol1
                               }
                               else {
                                   //おそらく右
                                   inputNumber = glanceSymbol2
                               }
                           }
                           else {
                               if (abs(directIrisDown.l) > abs(directIrisDown.r) ? directIrisDown.l : directIrisDown.r) > 0.0 {
                                   //おそらく左
                                   inputNumber = glanceSymbol1
                               }
                               else {
                                   //おそらく右
                                   inputNumber = glanceSymbol2
                               }
                           }
                       }else{
                           //一つ目のピーク時のxの掛け算と2つ目のピーク時のxの掛け算の大きい方(EyeGlance波形におけるxの掛け算は必ず正のため)で見る(大きい方が信頼できるから)
                           if (directUp > directDown) {
                               //lとrで絶対値が大きい方が選ばれ(左目と右目なので単純に大きい方が信頼できるから)、それが0未満なら以下の処理。そうでないならelse。
                               if (abs(directIrisUp.l) > abs(directIrisUp.r) ? directIrisUp.l : directIrisUp.r) > 0.0 {
                                   //おそらく左
                                   inputNumber = glanceSymbol1
                               }
                               else {
                                   //おそらく右
                                   inputNumber = glanceSymbol2
                               }
                           }
                           else {
                               if (abs(directIrisDown.l) > abs(directIrisDown.r) ? directIrisDown.l : directIrisDown.r) < 0.0 {
                                   //おそらく左
                                   inputNumber = glanceSymbol1
                               }
                               else {
                                   //おそらく右
                                   inputNumber = glanceSymbol2
                               }
                           }
                       }
                       
                       // メインスレッドでラベルのテキストを更新
                       DispatchQueue.main.async {
                           self.movementLabel.text = String(inputNumber)
                       }
                       inputResult = inputNumber
                       distGlanceNum = frameNum
                       //vowelNumberにinputNumberが入る。vowelで母音が決定される。inputNumberはglancesymbolが入っており、symbolは左か右かの判定結果が代入され、EyeGlanceの最終的な方向が代入される(1~4)
                       selectionDiscernment(vowelNumber: inputNumber) // 入力
                       allInit()
                   }
               }
               
               // 呼び出し
               //関数内でglanceDirrectionの判定を行うからここではとりあえずどちらの関数も投げてる
               updateGlanceLabel(glanceDirection: 4, glanceSymbol1: 1, glanceSymbol2: 2)
               updateGlanceLabel(glanceDirection: -4, glanceSymbol1: 3, glanceSymbol2: 4)
               
               //短すぎるeye glance初期化
               if ((glanceFlag == 4 || glanceFlag == -4) && frameNum - glanceFirstPoint <= 5) {
                   distGlanceInitNum = frameNum
                   glanceInit()
               }
               
               //長すぎるeye glance初期化
               if (glanceFlag != 0 && frameNum - glanceFirstPoint > 20) {
                   glanceInit()
               }
           }
       }
