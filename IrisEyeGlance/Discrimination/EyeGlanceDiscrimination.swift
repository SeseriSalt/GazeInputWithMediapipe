//
//  EyeGlanceDiscrimination.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/24.
//

import Foundation

var glanceUpFlag: Int = 0
var glanceDownFlag: Int = 0
var glanceFirstFrame: Int = 0
var distGlanceNum: Int = 0

var areaUp: CGFloat = 0.0
var areaDown: CGFloat = 0.0
var countAreaUp: CGFloat = 0.0
var countAreaDown: CGFloat = 0.0
var directUp: CGFloat = 0.0
var directIrisUp = lrPoint(l: CGFloat(0.0), r: CGFloat(0.0))
var directDown: CGFloat = 0.0
var directIrisDown = lrPoint(l: CGFloat(0.0), r: CGFloat(0.0))
var inputResult: Int = 0
var glanceEndFrame: Int = 0
var arrayAreaDown: [(frame: Int, area: CGFloat, direct_d: CGFloat, direct_i: lrPoint, isUsed: Bool)] = [(frame: 0, area: 0, direct_d: 0, direct_i: lrPoint(l: 0.0, r: 0.0), isUsed: false)]
var arrayAreaUp: [(frame: Int, area: CGFloat, direct_d: CGFloat, direct_i: lrPoint, isUsed: Bool)] = [(frame: 0, area: 0, direct_d: 0, direct_i: lrPoint(l: 0.0, r: 0.0), isUsed: false)]

extension ViewController {
    
    func eyeGlance(left: CGPoint, right: CGPoint, refDiff: CGPoint, ikichi: (max: CGFloat, min: CGFloat, areaup: CGFloat, areadown: CGFloat)) -> (glanceDist: CGFloat, directionDist: CGFloat, correctionValue: CGFloat) {
        //left, rightには左目と右目の1点差分のデータが入ってる(x, y座標が入ってる)
        //注意！！！！英瑠は左目と右目の平均を取ってから差分を取っていたが、ヤダさんは左目と右目でそれぞれ1点差分を取ってから左目と右目の平均を取っている
        // 鼻部の移動に対してかかる補正値
        var correctionValue = CGFloat(pow(0.9057236643, Double(abs(refDiff.y)) * 1000))
        correctionValue = correctionValue > 0.8 ? correctionValue : 0.301111111111111
        // Eye Glance判別波形
        let glanceDist = (left.y + right.y) / 2 * 800 * correctionValue
        let directionDist = left.x * right.x * 100000
        
        // Eye Glance判別
        if (frameNum > 15 && frameNum - distGlanceNum > 6 && frameNum - areaChangeFrame > 6 && frameNum - distBrinkNum > 6 && frameNum - distWinkNum > 6 && frameNum - distGlanceInitNum > 5) {
            eyeGlanceDitect(glanceDist: glanceDist, directionDist: directionDist, xPoint: lrPoint(l: left.x, r: right.x), ikichi: (max: ikichi.max, min: ikichi.min, areaup: ikichi.areaup, areadown: ikichi.areadown))
        }
        else{
            glanceInit()
        }
        return(glanceDist, directionDist, correctionValue)
    }
    
    func eyeGlanceDitect(glanceDist: CGFloat, directionDist: CGFloat, xPoint: lrPoint, ikichi: (max: CGFloat, min: CGFloat, areaup: CGFloat, areadown: CGFloat)) {
        //　xpoint(lrPoint)は左目xの差分値と右目xの差分値が入ってる
        // eye glance判別の閾値 上方向と下方向の移動で分ける
        //ikichi: (max: glanceIkichiMax, min: glanceIkichiMin, face: faceMoveIkichi).ikichidecesionでこう定義されている
        //glanceIkichiUpは目が上を向いた時(波形的には下向き)の時に使われるものと予想。だから、ikichiUPの方がikichiDownより小さい！！！
//        let glanceIkichiUpBig: CGFloat = ikichi.minBig
//        let glanceIkichiDownBig: CGFloat = ikichi.maxBig
        let glanceIkichiUpSmall: CGFloat = ikichi.min
        let glanceIkichiDownSmall: CGFloat = ikichi.max
        
        let frameLimit = frameNum - 15
        
        let WINK_IKITCH_AREAMAX: Float = winkIkichiMax * Float(winkAreaSliderValue)
        let WINK_IKITCH_AREAMIN: Float = winkIkichiMin * Float(winkAreaSliderValue)
        
        // eye glance判別開始
        // 目が上を見た時(波形的には下向き)
        if (glanceDownFlag == 0 && glanceDist < glanceIkichiUpSmall) {
            glanceDownFlag = 1
            glanceFirstFrame = frameNum
            // とりあえずxのピーク
            directDown = directionDist
            directIrisDown = xPoint
            areaDown += glanceDist
            countAreaDown += 1
            glanceEndFrame = frameNum
        }
        else if (glanceDownFlag == 1 && glanceDist < glanceIkichiUpSmall) {
            areaDown += glanceDist
            countAreaDown += 1
            glanceEndFrame = frameNum
            // xのピーク更新
            if (directDown < directionDist) {
                directDown = directionDist
                directIrisDown = xPoint
                //directIrisDownには左目xと右目xの差分値が入ってる
            }
        }
        else if (glanceDownFlag == 1 && glanceDist > glanceIkichiUpSmall) {
            glanceDownFlag = 2
            arrayAreaDown.insert((frame: glanceEndFrame, area: areaDown, direct_d: directDown, direct_i: directIrisDown, isUsed: false), at:0)
            if areaDown < ikichi.areadown && winkAreaUp > WINK_IKITCH_AREAMIN && winkAreaDown < WINK_IKITCH_AREAMAX {
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
                    if arrayAreaUp[i].area > ikichi.areaup && arrayAreaUp[i].isUsed == false{
                        glanceDownFlag = -4
                        arrayAreaDown[0].isUsed = true
                        arrayAreaUp[i].isUsed = true
                        directUp = arrayAreaUp[i].direct_d
                        directIrisUp = arrayAreaUp[i].direct_i
                        break
                    }
                }
            }
            if glanceDownFlag != -4 {
                glanceDownFlag = 0
                directDown = 0
                directIrisDown = lrPoint(l:0.0, r:0.0)
            }
            glanceEndFrame = 0
            areaDown = 0
        }
        //        if (glanceDownFlag == 1 && glanceDist > glanceIkichiUpSmall && glanceDownNext < glanceDownPeak) {
        //            glanceDownNext = glanceDist
        //        }
        
        // 目が下を見た時(波形的には上向き)
        if (glanceUpFlag == 0 && glanceDist > glanceIkichiDownSmall) {
            glanceUpFlag = -1
            glanceFirstFrame = frameNum
            directUp = directionDist
            directIrisUp = xPoint
            areaUp += glanceDist
            countAreaUp += 1
            glanceEndFrame = frameNum
        }
        else if (glanceUpFlag == -1 && glanceDist > glanceIkichiDownSmall) {
            areaUp +=  glanceDist
            countAreaUp += 1
            glanceEndFrame = frameNum
            // xのピーク更新
            if (directUp < directionDist) {
                directUp = directionDist
                directIrisUp = xPoint
                //directIrisDownには左目xと右目xの差分値が入ってる
            }
        }
        else if(glanceUpFlag == -1 && glanceDist < glanceIkichiDownSmall) {
            glanceUpFlag = -2
            arrayAreaUp.insert((frame: glanceEndFrame, area: areaUp, direct_d: directUp, direct_i: directIrisUp, isUsed: false), at:0)
            if areaUp > ikichi.areaup && winkAreaUp > WINK_IKITCH_AREAMIN && winkAreaDown < WINK_IKITCH_AREAMAX {
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
                    if arrayAreaDown[i].area < ikichi.areadown && arrayAreaDown[i].isUsed == false{
                        glanceUpFlag = 4
                        arrayAreaUp[0].isUsed = true
                        arrayAreaDown[i].isUsed = true
                        directDown = arrayAreaDown[i].direct_d
                        directIrisDown = arrayAreaDown[i].direct_i
                        break
                    }
                }
            }
            if glanceUpFlag != 4{
                glanceUpFlag = 0
                directUp = 0
                directIrisUp = lrPoint(l:0.0, r:0.0)
            }
            glanceEndFrame = 0
            areaUp = 0
        }
        //        if (glanceFlag == -1 && glanceDist < glanceIkichiDownSmall && glanceUpNext > glanceUpPeak) {
        //            glanceUpNext = glanceDist
        //        }
        
        // x方向決めのための値取得
        //        if (glanceFlag == 1 || glanceFlag == -1) {
        //            //x掛け算の最大値探し
        //            //xの掛け算は必ず正になる(左目と右目は同時に正もしくは負になるため掛け算は必ず正)
        //            if (firstDirect < directionDist) {
        //                firstDirect = directionDist
        //                //最大値更新
        //                firstDirectIris = xPoint
        //                //firstDirectIrisには左目xと右目xの差分値が入ってる
        //            }
        //        }
        //        else if (glanceFlag == 3 || glanceFlag == -3) {
        //            if (secondDirect < directionDist) {
        //                secondDirect = directionDist
        //                secondDirectIris = xPoint
        //            }
        //        }
        
        //glance判別関数
        func updateGlanceLabel(glanceDirection: Int, glanceSymbol1: Int, glanceSymbol2: Int) {
            //glanceflgaには今とれた上か下かの方向(4 or -4)が入っている
            if (glanceUpFlag == glanceDirection || glanceDownFlag == glanceDirection) {
                var inputNumber: Int
                if (glanceDownFlag == -4) {
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
    }
}
