//
//  Calibration.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2024/01/16.
//

import Foundation
import Accelerate

var pushTimes: Int = -1

var dataArrayRest: [CGFloat] = [0.0, 0.0]
var dataArray30: [[CGFloat]] = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
var dataAveRest: [CGFloat] = [0.0, 0.0]
var dataAve30: [CGFloat] = [0.0, 0.0]

extension ViewController {
    
    func getCalibrationData(left: CGPoint, right: CGPoint, refDiff: CGPoint) {
        let correctionValue = CGFloat(pow(0.8865681506, Double(abs(refDiff.y)) * 1000))
        // Eye Glance判別波形
        let glanceDist = (left.y + right.y) / 2 * 800 * correctionValue
        
        switch pushTimes {
        case 1:
            // 最大値の更新
            if dataArrayRest[0] < glanceDist {
                dataArrayRest[0] = glanceDist
            }
            // 最小値の更新
            if dataArrayRest[1] > glanceDist {
                dataArrayRest[1] = glanceDist
            }
        case 2:
            dataAveRest = roundFloatArray(floatArray: dataArrayRest)
            glanceSliderValue = dataAveRest[0] < abs(dataAveRest[1]) ? dataAveRest[0] + 0.1 : abs(dataAveRest[1]) + 0.1
            UserDefaults.standard.set(glanceSliderValue, forKey: "glanceSliderValue")
            
        case 3, 4, 5, 6, 7, 8, 9, 10:
            // 最大値の更新
            if dataArray30[pushTimes-3][0] < areaUp {
                dataArray30[pushTimes-3][0] = areaUp
            }
            // 最小値の更新
            if dataArray30[pushTimes-3][1] > areaDown {
                dataArray30[pushTimes-3][1] = areaDown
            }
                
        case 11:
            print("dataArray30: \(dataArray30)")
            // [max, min]
            dataAve30 =  calculateAverages(twoDimensionalArray: dataArray30) as? [CGFloat] ?? [0.0, 0.0]
            integralSliderValue = dataAve30[0] < abs(dataAve30[1]) ? round((dataAve30[0] - 0.1) / glanceSliderValue * 10)/10 : round((abs(dataAve30[1]) - 0.1) / glanceSliderValue * 10)/10
            UserDefaults.standard.set(integralSliderValue, forKey: "integralSliderValue")
            
            
            print("\n\n----------------------------------------------------")
            print("静止中最大値: \(dataAveRest[0]), 静止中最小値: \(dataAveRest[1])")
            print("Glance30cm最大値: \(dataAve30[0]), Glance30cm最小値: \(dataAve30[1])\n")
            print("glance閾値: \(glanceSliderValue)")
            print("積分値倍率: \(integralSliderValue)")
            print("----------------------------------------------------\n\n")
            dataArrayRest = [0.0, 0.0]
            dataArray30 = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
            
            pushTimes += 1
        default:
            break
        }
    }
    
    func calculateAverages(twoDimensionalArray: [[CGFloat]]) -> [CGFloat]? {
        guard twoDimensionalArray.count >= 4 else {
            // 配列が4つ未満の場合はnilを返す（条件に応じてエラーハンドリングを変更可能）
            return nil
        }

        // 1つ目の値を小さい方から4つ取り出し、平均を計算
        let firstValues = twoDimensionalArray.map { $0[0] }.sorted().prefix(4)
        let averageFirstValue = firstValues.reduce(0, +) / CGFloat(firstValues.count)

        // 2つ目の値を大きい方から4つ取り出し、平均を計算
        let secondValues = twoDimensionalArray.map { $0[1] }.sorted(by: >).prefix(4)
        let averageSecondValue = secondValues.reduce(0, +) / CGFloat(secondValues.count)
        

        return roundFloatArray(floatArray: [averageFirstValue, averageSecondValue])
    }
    
    func roundFloatArray(floatArray: [CGFloat]) -> [CGFloat] {
        let roundedArray = floatArray.map { round($0 * 10) / 10 }
        return roundedArray
    }
}
