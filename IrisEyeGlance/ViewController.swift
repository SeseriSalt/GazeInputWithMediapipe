//
//  ViewController.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2022/10/12.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, SYIrisDelegate {
    
    
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var leftLavel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var winkLabel: UILabel!
    
    @IBOutlet weak var firstPeak: UILabel!
    @IBOutlet weak var secondPeak: UILabel!
    
    @IBOutlet weak var lateFlagLabel: UILabel!
    
    let camera = Camera()
    let tracker: SYIris = SYIris()!
    
    public let FOCAL_LENGTH: Float = 1304.924438
    public let WIDTH: Float = 1080.0
    public let HEIGHT: Float = 1920.0
    public var frameNum: Int = 0
    
    var leftEyelidHeight: Float = 0.0
    var rightEyelidHeight: Float = 0.0
    var leftEyelidDiff: Float = 0.0
    var rightEyelidDiff: Float = 0.0
    var lrRatio: Float = 0.0
    var leftPrev: Float = -10000.0
    var rightPrev: Float = -10000.0
    var lrHeightDiff: Float = 0.0
    var lrDiff: Float = 0.0
    var simpleLrDiff: Float = 0.0
    
//    public let ikichiWink: Float = 0.6
    var determinedIkichiMax: Float = 0.0
    var determinedIkichiMin: Float = 0.0
    var determinedIkichBrink: Float = 0.0
    var determinedIkichiHeight: Float = 0.0
    var winkIkichiMaxNext: Float = 0.0
    var winkIkichiMinNext: Float = 0.0
    var brinkIkichNext: Float = 0.0
    var heightIkichiNext: Float = 0.0
    
    var winkFlag = 0
    var maxDiff: Float = 0.0
    var minDiff: Float = 0.0
    var maxPeakFrameNum = 0
    var minPeakFrameNum = 0
    var distInterval = 0
    var firstPoint = 0
    var labelFlag = 0
    var distFrameNum = 0
    var brinkFlag = 0
    var brinkFirstPoint = 0
    var brinkFrameNum = 0
    var leftDepthPrev: Float = 0.0
    var rightDepthPrev: Float = 0.0
    var depthAll: [[Float]] = []
    var defDepth: Float = 0.0
    var winkDatePrev = Date().timeIntervalSince1970
    var winkInterval = Date().timeIntervalSince1970
    
    var heightAll: [Float] = []
    
    var SampleList : [String] = ["left","left", "left", "right", "right", "right"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.setSampleBufferDelegate(self)
        camera.start()
        tracker.startGraph()
        tracker.delegate = self
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        tracker.processVideoFrame(pixelBuffer)
        
        frameNum += 1
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer!))
            self.label.text = "\(self.frameNum)"
        }
    }
    
    func irisTracker(_ irisTracker: SYIris!, didOutputLandmarks landmarks: [Landmark]!) {
        var landmarkAll : [[Float]] = []
        // matplotlibでのランドマーク位置描画用配列
//        var xPoints: [Float] = []
//        var yPoints: [Float] = []
        if let unwrapped = landmarks {
            for (point) in unwrapped {
                landmarkAll.append([point.x, point.y, point.z])
//                xPoints.append(point.x * WIDTH)
//                yPoints.append(point.y * HEIGHT)
            }
//            print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
//            print(xPoints)
//            print("?????????????????????????????????????????????")
//            print(yPoints)
            let leftEyeLandmark = [
                landmarkAll[468],
                landmarkAll[469],
                landmarkAll[470],
                landmarkAll[471],
                landmarkAll[472],
            ]
            let rightEyeLandmark = [
                landmarkAll[473],
                landmarkAll[474],
                landmarkAll[475],
                landmarkAll[476],
                landmarkAll[477],
            ]
            
            // Depthの計算・表示
            let leftIrisSize = caluclateIrisDiamater(landmark: leftEyeLandmark, imageSize: [WIDTH, HEIGHT])
            let rightIrisSize = caluclateIrisDiamater(landmark: rightEyeLandmark, imageSize: [WIDTH, HEIGHT])
            
            let leftDepth_mm = caluclateDepth(centerPoint: leftEyeLandmark[0] , focalLength: FOCAL_LENGTH, irisSize: leftIrisSize, width: WIDTH, height: HEIGHT)
            let rightDepth_mm = caluclateDepth(centerPoint: rightEyeLandmark[0], focalLength: FOCAL_LENGTH, irisSize: rightIrisSize, width: WIDTH, height: HEIGHT)
            
            let leftDepth = Int(round(leftDepth_mm / 10))
            let rightDepth = Int(round(rightDepth_mm / 10))
            
            DispatchQueue.main.async {
                self.leftLavel.text = "\(leftDepth)"
                self.rightLabel.text = "\(rightDepth)"
            }
            
        // winkの判別
            // 瞼の高さ
            leftEyelidHeight = getLandmerkLength(point0: landmarkAll[159], point1: landmarkAll[145], imageSize: [WIDTH, HEIGHT])
            rightEyelidHeight = getLandmerkLength(point0: landmarkAll[386], point1: landmarkAll[374], imageSize: [WIDTH, HEIGHT])
            
            // 1フレーム前の瞼の高さとの差分値
            leftEyelidDiff = leftEyelidHeight - leftPrev
            rightEyelidDiff = rightEyelidHeight - rightPrev
            
            // 左右の高さの絶対値
            lrHeightDiff = abs(leftEyelidHeight - rightEyelidHeight)
            
            // 左右の1フレーム前との差分値の差
            lrDiff = leftEyelidDiff - rightEyelidDiff
            
            // 左右の高さの差
            simpleLrDiff = leftEyelidHeight - rightEyelidHeight
            
            // 左右の高さの差を記録していく
            heightAll.insert(simpleLrDiff, at: 0)
            var heightAvg5: Float = 0
            if (heightAll.count >= 8) {
                for i in (2 ..< 7) {
                    heightAvg5 += heightAll[i]
                }
                heightAvg5 = heightAvg5 / 5
            }
            
            // 1フレーム前の距離との差分
            let leftDepthDiff = leftDepth_mm - leftDepthPrev
            let rightDepthDiff = rightDepth_mm - rightDepthPrev
            
            // 距離の平均値
            let lrDepthVer: Float = (leftDepth_mm + rightDepth_mm) / 2.0
            
            // 1フレーム前の距離との差分の平均値（距離の変更時の雑音を取り除こうとして取得したが、今のとこ使ってない）
            let lrDepthDiff: Float = (leftDepthDiff + rightDepthDiff) / 2.0
            
            depthAll.append([lrDepthVer, lrDepthDiff])
        
            // 5フレーム前のdepthの取得
            if depthAll.count == 5 {
                defDepth = depthAll.last![0]
                depthAll.removeFirst()
            }
            
            // 距離から次のフレームの閾値の導出
            winkIkichiMaxNext = -0.01244 * defDepth + 9.524
            winkIkichiMinNext = -winkIkichiMaxNext
            brinkIkichNext = winkIkichiMinNext
            heightIkichiNext = -0.03 * defDepth + 23
            
            
            DispatchQueue.main.async {
                self.firstPeak.textColor = UIColor.white
                self.secondPeak.textColor = UIColor.white
                self.lateFlagLabel.textColor = UIColor.black
                self.lateFlagLabel.text = "...."
            }
            
            // 判別に用いる閾値の決定
            let WINK_IKITCH_MAX: Float = determinedIkichiMax
            let WINK_IKITCH_MIN: Float = determinedIkichiMin
            let BRINK_IKICHI: Float = determinedIkichBrink
            let HEIGHT_DIFF_IKICHI: Float = determinedIkichiHeight

            // 左目のWink判別
            if (winkFlag == 0 && lrDiff < WINK_IKITCH_MIN && frameNum > 15 && frameNum - distFrameNum > 6 && frameNum - brinkFrameNum > 6) {
                winkFlag = 1
                minDiff = lrDiff
                minPeakFrameNum = frameNum
                firstPoint = frameNum
                DispatchQueue.main.async {
                    self.firstPeak.text = String(format: "%.3f", self.minDiff)
                    self.firstPeak.textColor = UIColor.systemPink
                }
            }
            else if (winkFlag == 1 && lrDiff < minDiff) {
                minDiff = lrDiff
                minPeakFrameNum = frameNum
                DispatchQueue.main.async {
                    self.firstPeak.text = String(format: "%.3f", self.minDiff)
                    self.firstPeak.textColor = UIColor.systemPink
                }
            }
            else if (winkFlag == 1 && lrDiff > WINK_IKITCH_MIN) {
                winkFlag = 2
            }
            else if (winkFlag == 2 && lrDiff > WINK_IKITCH_MAX) {
                winkFlag = 3
                maxDiff = lrDiff
                maxPeakFrameNum = frameNum
                DispatchQueue.main.async {
                    self.secondPeak.text = String(format: "%.3f", self.maxDiff)
                    self.secondPeak.textColor = UIColor.systemPink
                }
            }
            else if (winkFlag == 3 && lrDiff > maxDiff) {
                maxDiff = lrDiff
                maxPeakFrameNum = frameNum
                DispatchQueue.main.async {
                    self.secondPeak.text = String(format: "%.3f", self.maxDiff)
                    self.secondPeak.textColor = UIColor.systemPink
                }
            }
            else if (winkFlag == 3 && lrDiff < WINK_IKITCH_MAX) {
                winkFlag = 4
            }
            else if (heightAvg5 < -HEIGHT_DIFF_IKICHI && lrDiff > WINK_IKITCH_MAX) {
                winkFlag = 4
                DispatchQueue.main.async {
                    self.lateFlagLabel.text = "Late Left"
                    self.secondPeak.textColor = UIColor.blue
                }
            }//瞬きの回避
            else if (brinkFlag == 0 && frameNum - brinkFrameNum > 5 && leftEyelidDiff < BRINK_IKICHI && rightEyelidDiff < BRINK_IKICHI) {
                brinkFlag = 1
                brinkFirstPoint = frameNum
            }
            else if (brinkFlag == 1 && leftEyelidDiff > -BRINK_IKICHI && rightEyelidDiff > -BRINK_IKICHI && frameNum - brinkFirstPoint <= 4) {
                brinkFlag = 2
            }
            
            // 右目のWink判別
            if (winkFlag == 0 && lrDiff > WINK_IKITCH_MAX && frameNum > 15 && frameNum - distFrameNum > 6 && frameNum - brinkFrameNum > 6) {
                winkFlag = -1
                maxDiff = lrDiff
                maxPeakFrameNum = frameNum
                firstPoint = frameNum
                DispatchQueue.main.async {
                    self.firstPeak.text = String(format: "%.3f", self.maxDiff)
                    self.firstPeak.textColor = UIColor.systemPink
                }
            }
            else if (winkFlag == -1 && lrDiff > maxDiff) {
                maxDiff = lrDiff
                maxPeakFrameNum = frameNum
                DispatchQueue.main.async {
                    self.firstPeak.text = String(format: "%.3f", self.maxDiff)
                    self.firstPeak.textColor = UIColor.systemPink
                }
            }
            else if (winkFlag == -1 && lrDiff < WINK_IKITCH_MAX) {
                winkFlag = -2
            }
            else if (winkFlag == -2 && lrDiff < WINK_IKITCH_MIN) {
                winkFlag = -3
                minDiff = lrDiff
                minPeakFrameNum = frameNum
                DispatchQueue.main.async {
                    self.secondPeak.text = String(format: "%.3f", self.minDiff)
                    self.secondPeak.textColor = UIColor.systemPink
                }
            }
            else if (winkFlag == -3 && lrDiff < minDiff) {
                minDiff = lrDiff
                minPeakFrameNum = frameNum
                DispatchQueue.main.async {
                    self.secondPeak.text = String(format: "%.3f", self.maxDiff)
                    self.secondPeak.textColor = UIColor.systemPink
                }
            }
            else if (winkFlag == -3 && lrDiff > WINK_IKITCH_MIN) {
                winkFlag = -4
            }
            else if (heightAvg5 > HEIGHT_DIFF_IKICHI && lrDiff < WINK_IKITCH_MIN) {
                winkFlag = -4
                DispatchQueue.main.async {
                    self.lateFlagLabel.text = "Late Right"
                    self.secondPeak.textColor = UIColor.red
                }
            }//瞬きの回避
            else if (brinkFlag == 0 && frameNum - brinkFrameNum > 5 && leftEyelidDiff < BRINK_IKICHI && rightEyelidDiff < BRINK_IKICHI) {
                brinkFlag = 1
                brinkFirstPoint = frameNum
            }
            else if (brinkFlag == 1 && leftEyelidDiff > -BRINK_IKICHI && rightEyelidDiff > -BRINK_IKICHI && frameNum - brinkFirstPoint <= 4) {
                brinkFlag = 2
            }
            
            // ピーク間隔が短すぎる時の初期化
            if ((winkFlag == 4 || winkFlag == -4) && frameNum - firstPoint < 5) {
                if (heightAvg5 <= HEIGHT_DIFF_IKICHI && -HEIGHT_DIFF_IKICHI <= heightAvg5) {
                    winkFlag = 0
                    maxDiff = 0
                    minDiff = 0
                    maxPeakFrameNum = 0
                    minPeakFrameNum = 0
                }
            }
            
        // 出力のフラグ立てと初期化
            // 瞬き
            if (brinkFlag == 2) {
                brinkFlag = 0
                brinkFrameNum = frameNum
                
                winkFlag = 0
                minDiff = 0
                maxDiff = 0
                maxPeakFrameNum = 0
                minPeakFrameNum = 0
            }
            // wink
            if (winkFlag == 4 || winkFlag == -4) {
                // ピーク感覚が5フレーム以上10フレーム以下の時、wink入力判定
                if (abs(maxPeakFrameNum - minPeakFrameNum) >= 5 || abs(maxPeakFrameNum - minPeakFrameNum) <= 10) {
                    labelFlag = winkFlag == 4 ? 1 : 2
                    distInterval = maxPeakFrameNum - minPeakFrameNum
                    winkFlag = 0
                    minDiff = 0
                    maxDiff = 0
                    maxPeakFrameNum = 0
                    minPeakFrameNum = 0
                    distFrameNum = frameNum
                    winkInterval = Date().timeIntervalSince1970 - winkDatePrev
                    winkDatePrev = Date().timeIntervalSince1970
                }
            }
            
            
            // winkLabelの出力
            if (frameNum - brinkFrameNum <= 6) {
                DispatchQueue.main.async {
                    self.winkLabel.textColor = UIColor.green
                    self.winkLabel.text = "Brink."
                }
            }
            else if (frameNum - distFrameNum <= 6 && labelFlag == 1) {
                DispatchQueue.main.async {
                    self.winkLabel.textColor = UIColor.blue
                    self.winkLabel.text = "Left Wink!!"
                }
            }
            else if (frameNum - distFrameNum <= 6 && labelFlag == 2) {
                DispatchQueue.main.async {
                    self.winkLabel.textColor = UIColor.red
                    self.winkLabel.text = "Right Wink!!"
                }
            }
            else {
                DispatchQueue.main.async {
                    self.winkLabel.textColor = UIColor(white:1.0, alpha:0.4)
                    self.winkLabel.text = "No Input"
                }
                labelFlag = 0
            }
            
            // ピーク感覚が長すぎる時の初期化
            if (winkFlag != 0 && frameNum - firstPoint > 13) {
                winkFlag = 0
                maxDiff = 0
                minDiff = 0
                maxPeakFrameNum = 0
                minPeakFrameNum = 0
            }
            // 瞬きが失敗？した時の初期化
            if (brinkFlag != 0 && frameNum - brinkFirstPoint > 4) {
                brinkFlag = 0
            }
            
            // 波形の出力
            var printIkichMax: Float = 0.0
            var printIkichMin: Float = 0.0
            var printIkichBrink: Float = 0.0
            if (winkFlag != 0) {
                printIkichMax = WINK_IKITCH_MAX
                printIkichMin = WINK_IKITCH_MIN
            }
            if (brinkFlag != 0) {
                printIkichBrink = BRINK_IKICHI
                
                printIkichMax = WINK_IKITCH_MAX
                printIkichMin = WINK_IKITCH_MIN
            }
            
            var printWinkFrame: Int = 0
            var printBrinkFrame: Int = 0
            if (distFrameNum == frameNum) {
                printWinkFrame = distFrameNum
            }
            
            if (brinkFrameNum == frameNum) {
                printBrinkFrame = brinkFrameNum
            }

            //実験データ出力
            print("\(frameNum), \(leftEyelidHeight), \(rightEyelidHeight), \(lrHeightDiff), \(frameNum), \(defDepth / 10.0), \(frameNum), \(leftEyelidDiff), \(rightEyelidDiff), \(BRINK_IKICHI), \(printIkichBrink), \(-printIkichBrink), \(Double(brinkFlag) * 4.5),  \(frameNum), \(simpleLrDiff), \(heightAvg5), \(HEIGHT_DIFF_IKICHI), \(frameNum), \(lrDiff), \(WINK_IKITCH_MIN), \(WINK_IKITCH_MAX), \(printIkichMin), \(printIkichMax), \(winkFlag * 5), \(printWinkFrame), \(printBrinkFrame), \(winkInterval)")
            
//            print("\(frameNum), \(leftDepth_mm), \(rightDepth_mm), \(abs(leftDepth_mm - rightDepth_mm)), \(frameNum),\(leftDepthDiff), \(rightDepthDiff), \(abs(leftDepthDiff - rightDepthDiff)), \(frameNum), \(leftEyelidDiff), \(rightEyelidDiff), \(lrDiff)")
            
        
            
// ↓ここから下：次のフレームで使用する現在の値を保存・初期化
            leftPrev = leftEyelidHeight
            rightPrev = rightEyelidHeight
            
            leftDepthPrev = leftDepth_mm
            rightDepthPrev = rightDepth_mm
            
            // フラグが立っていない時のみ閾値を更新（フラグが立っている時、閾値はフラグが立ったフレームの値）
            if (winkFlag == 0) {
                determinedIkichiMax = winkIkichiMaxNext
                determinedIkichiMin = winkIkichiMinNext
                determinedIkichiHeight = heightIkichiNext
            }
            
            if (brinkFlag == 0) {
                determinedIkichBrink = brinkIkichNext
                
                if (winkFlag == 0) {
                    // 瞬きの時はwinkも止める
                    determinedIkichiMax = winkIkichiMaxNext
                    determinedIkichiMin = winkIkichiMinNext
                    determinedIkichiHeight = heightIkichiNext
                }
            }
            
            
            
            winkInterval = 0
            distInterval = 0 //ナニコレ
        }
    }
    
    func irisTracker(_ irisTracker: SYIris!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
        }
    }
}

