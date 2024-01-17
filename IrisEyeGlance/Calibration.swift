//
//  Calibration.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2024/01/16.
//

import Foundation
import Accelerate


extension ViewController {
    
    func getCalibrationData(left: CGPoint, right: CGPoint, refDiff: CGPoint) {
        let correctionValue = CGFloat(pow(0.8865681506, Double(abs(refDiff.y)) * 1000))
        // Eye Glance判別波形
        let glanceDist = (left.y + right.y) / 2 * 800 * correctionValue
        
        switch pushTimes {
        case 1, 2, 3, 4, 5, 6, 7, 8:
            // 最大値の更新
            if dataArray20[pushTimes-1][0] < glanceDist {
                dataArray20[pushTimes-1][0] = glanceDist
            }
            // 最小値の更新
            if dataArray20[pushTimes-1][1] > glanceDist {
                dataArray20[pushTimes-1][1] = glanceDist
            }
            
        case 10, 11, 12, 13, 14, 15, 16, 17:
            // 最大値の更新
            if dataArray30[pushTimes-10][0] < glanceDist {
                dataArray30[pushTimes-10][0] = glanceDist
            }
            // 最小値の更新
            if dataArray30[pushTimes-10][1] > glanceDist {
                dataArray30[pushTimes-10][1] = glanceDist
            }
            
        case 19, 20, 21, 22, 23, 24, 25, 26:
            // 最大値の更新
            if dataArray40[pushTimes-19][0] < glanceDist {
                dataArray40[pushTimes-19][0] = glanceDist
            }
            // 最小値の更新
            if dataArray40[pushTimes-19][1] > glanceDist {
                dataArray40[pushTimes-19][1] = glanceDist
            }
            
        case 27:
            print("dataArray20: \(dataArray20)")
            print("dataArray30: \(dataArray30)")
            print("dataArray40: \(dataArray40)")
            // [maxBig, minBig, maxSamll, minSmall]
            var dataAve20: [CGFloat] = [0.0, 0.0, 0.0, 0.0]
            var dataAve30: [CGFloat] = [0.0, 0.0, 0.0, 0.0]
            var dataAve40: [CGFloat] = [0.0, 0.0, 0.0, 0.0]
            for i in 0...1 {
                var ave20: CGFloat = 0
                var ave30: CGFloat = 0
                var ave40: CGFloat = 0
                for j in 0...1 {
                    ave20 += dataArray20[j][i] + dataArray20[j + 4][i]
                    ave30 += dataArray30[j][i] + dataArray30[j + 4][i]
                    ave40 += dataArray40[j][i] + dataArray40[j + 4][i]
                }
                dataAve20[i] = ave20 / 4
                dataAve30[i] = ave30 / 4
                dataAve40[i] = ave40 / 4
                ave20 = 0
                ave30 = 0
                ave40 = 0
                for j in 2...3 {
                    ave20 += dataArray20[j][i] + dataArray20[j + 4][i]
                    ave30 += dataArray30[j][i] + dataArray30[j + 4][i]
                    ave40 += dataArray40[j][i] + dataArray40[j + 4][i]
                }
                dataAve20[i + 2] = ave20 / 4
                dataAve30[i + 2] = ave30 / 4
                dataAve40[i + 2] = ave40 / 4
            }
            print("\n\n----------------------------------------------------")
            print("キャリブレーション40終了:\(frameNum)")
            print("dataAve20: \(dataAve20)")
            print("dataAve30: \(dataAve30)")
            print("dataAve40: \(dataAve40)")
            for i in 0...3 {
                let n = (i == 0 || i == 1) ? 0.6 : 1.5
                let resultTh = calculateLinearRegression(x: [20.0, 30.0, 40.0], y: [dataAve20[i % 2] * n, dataAve30[i % 2] * n, dataAve40[i % 2] * n])
                eyeGlanceThBig[i * 2] = resultTh?.slope ?? 1.0
                eyeGlanceThBig[i * 2 + 1] = resultTh?.intercept ?? 0.0
            }
            for i in 0...3 {
                let n = (i == 0 || i == 1) ? 0.6 : 1.5
                let resultTh = calculateLinearRegression(x: [20.0, 30.0, 40.0], y: [dataAve20[i % 2 + 2] * n, dataAve30[i % 2 + 2] * n, dataAve40[i % 2 + 2] * n])
                eyeGlanceThSmall[i * 2] = resultTh?.slope ?? 1.0
                eyeGlanceThSmall[i * 2 + 1] = resultTh?.intercept ?? 0.0
            }
            print("eyeGlanceThBig, \(eyeGlanceThBig)")
            print("eyeGlanceThSmall, \(eyeGlanceThSmall)\n")
            print("----------------------------------------------------\n\n")
            
            pushTimes += 1
        default:
            break
        }
        
        func calculateLinearRegression(x: [CGFloat], y: [CGFloat]) -> (slope: CGFloat, intercept: CGFloat)? {
            guard x.count == y.count && x.count >= 2 else {
                return nil // エラー：xとyの要素数が一致しないか、2つ未満
            }

            let n = CGFloat(x.count)

            // Σxi, Σyi, Σxiyi, Σxi^2 の計算
            let sumX = x.reduce(0, +)
            let sumY = y.reduce(0, +)
            let sumXY = zip(x, y).map { $0 * $1 }.reduce(0, +)
            let sumXSquare = x.map { $0 * $0 }.reduce(0, +)

            // 傾きと切片の計算
            let slope = (n * sumXY - sumX * sumY) / (n * sumXSquare - sumX * sumX)
            let intercept = (sumY - slope * sumX) / n

            return (slope, intercept)
        }
    }
}
