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
    var lrAbsDiff: Float = 0.0
    var lrDiff: Float = 0.0
    
//    public let ikichiWink: Float = 0.6
    var winkFlag = 0
    var maxDiff: Float = 0.0
    var minDiff: Float = 0.0
    var maxPeakFrameNum = 0
    var minPeakFrameNum = 0
    var distInterval = 0
    var firstPoint = 0
    var labelFlag = 0
    var distFrameNum = 0
    var brink = 0
    var brinkFrameNum = 0
    var leftDepthPrev: Float = 0.0
    var rightDepthPrev: Float = 0.0
    
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
            
            // 1フレーム前の瞼の高さとの差分
            leftEyelidDiff = leftEyelidHeight - leftPrev
            rightEyelidDiff = rightEyelidHeight - rightPrev
            
            // 左右の高さの絶対値
            lrHeightDiff = abs(leftEyelidHeight - rightEyelidHeight)
            
            // 左右の高さの絶対値の差分
            lrAbsDiff =  abs(leftEyelidDiff) - abs(rightEyelidDiff)
            
            // 左右の高さの差分
            lrDiff = leftEyelidDiff - rightEyelidDiff
            
    
            // 瞬き回避
            let WINK_IKITCH_MIN: Float = -8.0
            let WINK_IKITCH_MAX: Float = 8.0
            let BRINK_IKICHI: Float = -8.0
            
            if (frameNum - brinkFrameNum > 6 && leftEyelidDiff < BRINK_IKICHI && rightEyelidDiff < BRINK_IKICHI ) {
                brink = 1
                brinkFrameNum = frameNum
//                print("brink ???????????????????")
            }
            // 判別開始 左目
            if (winkFlag == 0 && lrDiff < WINK_IKITCH_MIN && frameNum > 15 && frameNum - distFrameNum > 6 && frameNum - brinkFrameNum > 6) {
                winkFlag = 1
                minDiff = lrDiff
                minPeakFrameNum = frameNum
                firstPoint = frameNum
//                print("first!!!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == 1 && lrDiff < minDiff) {
                minDiff = lrDiff
                minPeakFrameNum = frameNum
//                print("update!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == 1 && lrDiff > WINK_IKITCH_MIN) {
                winkFlag = 2
//                print("flag = 2!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == 2 && lrDiff > WINK_IKITCH_MAX) {
                winkFlag = 3
                maxDiff = lrDiff
                maxPeakFrameNum = frameNum
//                print("flag = 3!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == 3 && lrDiff > maxDiff) {
                maxDiff = lrDiff
                maxPeakFrameNum = frameNum
//                print("update!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == 3 && lrDiff < WINK_IKITCH_MAX) {
                winkFlag = 4
//                print("flag = 4!!!!!!!!!!!!!!!!!!!")
            }
            
            // 右目
            if (winkFlag == 0 && lrDiff > WINK_IKITCH_MAX && frameNum > 15 && frameNum - distFrameNum > 6 && frameNum - brinkFrameNum > 6) {
                winkFlag = -1
                maxDiff = lrDiff
                maxPeakFrameNum = frameNum
                firstPoint = frameNum
//                print("first!!!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == -1 && lrDiff > maxDiff) {
                maxDiff = lrDiff
                maxPeakFrameNum = frameNum
//                print("update!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == -1 && lrDiff < WINK_IKITCH_MAX) {
                winkFlag = -2
//                print("flag = 2!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == -2 && lrDiff < WINK_IKITCH_MIN) {
                winkFlag = -3
                minDiff = lrDiff
                minPeakFrameNum = frameNum
//                print("flag = 3!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == -3 && lrDiff < minDiff) {
                minDiff = lrDiff
                minPeakFrameNum = frameNum
//                print("update!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == -3 && lrDiff > WINK_IKITCH_MIN) {
                winkFlag = -4
//                print("flag = 4!!!!!!!!!!!!!!!!!!!")
            }
            
            // 出力前のフラグ立てと初期化
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
                }
            }
            
            // winkLabelの出力変更
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
                    self.winkLabel.textColor = UIColor.black
                    self.winkLabel.text = "No Input"
                }
                labelFlag = 0
            }
            
            // ピーク間隔が短すぎる時の初期化
            if ((winkFlag == 4 || winkFlag == -4) && frameNum - firstPoint < 5) {
                winkFlag = 0
                maxPeakFrameNum = 0
                minPeakFrameNum = 0
            }
            
            // ピーク感覚が長すぎる時の初期化
            if (winkFlag != 0 && frameNum - firstPoint > 10) {
                winkFlag = 0
                maxPeakFrameNum = 0
                minPeakFrameNum = 0
//                print("reset!!!!!!!!!!!!!!!!!!!")
            }
         
            let leftDepthDiff = leftDepth_mm - leftDepthPrev
            let rightDepthDiff = rightDepth_mm - rightDepthPrev
            
            // 波形の出力
//            print("\(frameNum), \(leftEyelidHeight), \(rightEyelidHeight), \(lrHeightDiff), \(frameNum), \(leftEyelidDiff), \(rightEyelidDiff), \(lrDiff) ,\(winkFlag * 5), \(distFrameNum), \(brinkFrameNum)")
//            print("\(frameNum), \(leftDepth_mm), \(rightDepth_mm), \(abs(leftDepth_mm - rightDepth_mm)), \(frameNum),\(leftDepthDiff), \(rightDepthDiff), \(abs(leftDepthDiff - rightDepthDiff)), \(frameNum), \(leftEyelidDiff), \(rightEyelidDiff), \(lrDiff)")
            
            leftPrev = leftEyelidHeight
            rightPrev = rightEyelidHeight
            
            leftDepthPrev = leftDepth_mm
            rightDepthPrev = rightDepth_mm
            
            distInterval = 0
        }
    }
    
    func irisTracker(_ irisTracker: SYIris!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
        }
    }
}

