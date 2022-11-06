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
    var leftEyelidRatio: Float = 0.0
    var rightEyelidRatio: Float = 0.0
    var lrRatio: Float = 0.0
    var leftPrev: Float = -10000.0
    var rightPrev: Float = -10000.0
    var lrDiff: Float = 0.0
    
//    public let ikichiWink: Float = 0.6
    var winkFlag = 0
    var maxDiff: Float = 0.0
    var peakFrameNum = 0
    var distFrameNum = 0
    var brink = 0
    var brinkFrameNum = 0
    
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
            
            // 1フレーム前の瞼の高さとの変化量
            leftEyelidRatio = leftEyelidHeight / leftPrev
            rightEyelidRatio = rightEyelidHeight / rightPrev
            
            // 左右の差分の絶対値
            lrDiff = abs(leftEyelidRatio - rightEyelidRatio)
            
            // 波形の出力
            print("\(frameNum), \(leftEyelidHeight), \(rightEyelidHeight), \(leftEyelidRatio), \(rightEyelidRatio), \(lrDiff)")
            
    
            // 瞬き回避
            if ((leftEyelidHeight + rightEyelidHeight) / 2 < 0.5 ) {
                brinkFrameNum = frameNum
            }
            // 判別開始
            let WINK_IKITCH: Float = 0.12
            if (winkFlag == 0 && lrDiff > WINK_IKITCH && frameNum > 15 && frameNum - distFrameNum > 6 && frameNum - brinkFrameNum > 6) {
                winkFlag = 1
                maxDiff = lrDiff
                peakFrameNum = frameNum   // 現在使っていない
//                print("first!!!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == 1 && lrDiff > maxDiff) {
                maxDiff = lrDiff
                peakFrameNum = frameNum
//                print("update!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == 1 && lrDiff < WINK_IKITCH) {
                winkFlag = 2
//                print("flag = 2!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == 2 && lrDiff > WINK_IKITCH) {
                winkFlag = 3
//                print("flag = 3!!!!!!!!!!!!!!!!!!!")
            }
            else if (winkFlag == 3 && lrDiff < WINK_IKITCH) {
                winkFlag = 4
//                print("flag = 4!!!!!!!!!!!!!!!!!!!")
            }
            
            // 出力
            if (winkFlag == 4) {
//                print("wink!!!!!!!!!!!!!!!!!!!!!!!")
                winkFlag = 0
                peakFrameNum = 0
                distFrameNum = frameNum
            }
            if  (frameNum - distFrameNum < 10) {
                DispatchQueue.main.async {
                    self.winkLabel.text = "Wink!!"
                }
            }
            else if (frameNum - brinkFrameNum < 10) {
                DispatchQueue.main.async {
                    self.winkLabel.text = "Brink."
                }
            }
            else {
                DispatchQueue.main.async {
                    self.winkLabel.text = "No Input"
                }
            }
            
            // winkに失敗した時の初期化
            if (winkFlag != 0 && frameNum - peakFrameNum > 11) {
                winkFlag = 0
                peakFrameNum = 0
//                print("reset!!!!!!!!!!!!!!!!!!!")
            }
            
            leftPrev = leftEyelidHeight
            rightPrev = rightEyelidHeight
        }
    }
    
    func irisTracker(_ irisTracker: SYIris!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
        }
    }
}

