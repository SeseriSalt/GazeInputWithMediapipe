//
//  EyeGlanceDiscrimination.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/24.
//

import Foundation

var glanceFlag: Int = 0
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
    
    func eyeGlance(left: CGPoint, right: CGPoint, refDiff: CGPoint, ikichi: (max: CGFloat, min: CGFloat, areaup: CGFloat, areadown:CGFloat)) -> (glanceDist: CGFloat, directionDist: CGFloat, correctionValue: CGFloat) {
        //left, rightには左目と右目の1点差分のデータが入ってる(x, y座標が入ってる)
        //注意！！！！英瑠は左目と右目の平均を取ってから差分を取っていたが、ヤダさんは左目と右目でそれぞれ1点差分を取ってから左目と右目の平均を取っている
        // 鼻部の移動に対してかかる補正値
        let correctionValue = CGFloat(pow(0.8865681506, Double(abs(refDiff.y)) * 1000))
        // Eye Glance判別波形
        let glanceDist = (left.y + right.y) / 2 * 800 * correctionValue
        let directionDist = left.x * right.x * 100000
        
        // Eye Glance判別
        if (frameNum > 15 && frameNum - distGlanceNum > 6 /*&& frameNum - areaChangeFrame > 6*/ && frameNum - distBrinkNum > 6 && frameNum - distWinkNum > 6 && frameNum - distGlanceInitNum > 5) {
            eyeGlanceDitect(glanceDist: glanceDist, directionDist: directionDist, xPoint: lrPoint(l: left.x, r: right.x), ikichi: (max: ikichi.max, min: ikichi.min, ikichi.areaup, ikichi.areadown))
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
        let glanceIkichiUp: CGFloat = ikichi.min
        let glanceIkichiDown: CGFloat = ikichi.max
        
        let frameLimit = frameNum - 20
        
        // eye glance判別開始
        // 目が上を見た時(波形的には下向き)
        if (glanceFlag == 0 && glanceDist < glanceIkichiUp) {
            glanceFlag = 1
            glanceFirstFrame = frameNum
            // とりあえずxの最大値(記録)
            directDown = directionDist
            directIrisDown = xPoint
            areaDown += (glanceDist / glanceIkichiUp) * glanceDist
            countAreaDown += 1
            glanceEndFrame = frameNum
        }
        else if (glanceFlag == 1 && glanceDist < glanceIkichiUp) {
            areaDown += (glanceDist / glanceIkichiUp) * glanceDist //
            countAreaDown += 1
            glanceEndFrame = frameNum
            if (directDown < directionDist) {
                directDown = directionDist
                //最大値更新
                directIrisDown = xPoint
                //directIrisDownには左目xと右目xの差分値が入ってる
            }
        }
        else if (glanceFlag == 1 && glanceDist > 0.0) {
            glanceFlag = 2
            arrayAreaDown.insert((frame: glanceEndFrame, area: areaDown, direct_d: directDown, direct_i: directIrisDown, isUsed: false), at:0)
            if areaDown < ikichi.areadown {
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
            glanceEndFrame = 0
            areaDown = 0
        }
        else if (glanceFlag == 0 && glanceDist > glanceIkichiDown) {
            glanceFlag = -1
            glanceFirstFrame = frameNum
            directUp = directionDist
            directIrisUp = xPoint
            areaUp += (glanceDist / glanceIkichiDown) * glanceDist
            countAreaUp += 1
            glanceEndFrame = frameNum
        }
        else if (glanceFlag == -1 && glanceDist > glanceIkichiDown) {
            areaUp += (glanceDist / glanceIkichiDown) * glanceDist
            countAreaUp += 1
            glanceEndFrame = frameNum
            if (directUp < directionDist) {
                directUp = directionDist
                //最大値更新
                directIrisUp = xPoint
                //directIrisDownには左目xと右目xの差分値が入ってる
            }
        }
        else if(glanceFlag == -1 && glanceDist < 0.0) {
            glanceFlag = -2
            arrayAreaUp.insert((frame: glanceEndFrame, area: areaUp, direct_d: directUp, direct_i: directIrisUp, isUsed: false), at:0)
            if areaUp > ikichi.areaup {
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
            glanceEndFrame = 0
            areaUp = 0
        }
        
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
        if ((glanceFlag == 4 || glanceFlag == -4) && frameNum - glanceFirstFrame <= 5) {
            distGlanceInitNum = frameNum
            glanceInit()
        }
        
        //長すぎるeye glance初期化
        if (glanceFlag != 0 && frameNum - glanceFirstFrame > 15) {
            glanceInit()
        }
    }
}
