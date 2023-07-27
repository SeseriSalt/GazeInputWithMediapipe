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
    @IBOutlet weak var frameLabel: UILabel!
    @IBOutlet weak var leftLavel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    @IBOutlet weak var firstPeak: UILabel!
    @IBOutlet weak var secondPeak: UILabel!
    @IBOutlet weak var lateFlagLabel: UILabel!
    
    @IBOutlet weak var inputLabel: UILabel!
    @IBOutlet weak var imputDesignImage: UIImageView!
    @IBOutlet weak var ISCenterLabel: UILabel!
    @IBOutlet weak var ISWidthLabel: UILabel!
    
    @IBOutlet weak var questionLabel: UILabel!
    
    @IBOutlet weak var movementLabel: UILabel!
    
    @IBOutlet weak var settingButton: UIButton!
    
    
    let camera = Camera()
    let tracker: SYIris = SYIris()!
    
    public let FOCAL_LENGTH: Float = 1304.924438
    public let WIDTH: Float = 1080.0
    public let HEIGHT: Float = 1920.0
    public var frameNum: Int = 0
    
    // 1つのランドマークの構造体
    struct landmarkPoint {
        var x: Float = 0.0
        var y: Float = 0.0
    }
    // 右左の構造体
    struct lrPoint {
        var l: CGFloat = 0.0
        var r: CGFloat = 0.0
    }
    
    // x軸正規化の最小値・最大値
    let NORMALIZED_CONST: (min: CGFloat, max: CGFloat) = (min: 0.08978804, max: 0.9095595)
    
    var leftEyelidHeight: Float = 0.0
    var rightEyelidHeight: Float = 0.0
    var leftEyelidDiff: Float = 0.0
    var rightEyelidDiff: Float = 0.0
    var lrRatio: Float = 0.0
    var leftPrev: Float = 0.0
    var rightPrev: Float = 0.0
    var lrHeightDiff: Float = 0.0
    var lrDiff: Float = 0.0
    var lrDiffPrev: Float = 0.0
    
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
    var lateWinkFlag = 0
    var moveMissjudgeFlag = 0
    var maxDiff: Float = 0.0
    var minDiff: Float = 0.0
    var peakPrev: Float = 0.0
    var peakNext: Float = 0.0
    var maxPeakFrameNum = 0
    var minPeakFrameNum = 0
    var firstPoint = 0
    var inputLabelFlag = 0
    var distWinkNum = 0
    var brinkFlag = 0
    var brinkFirstPoint = 0
    var distBrinkNum = 0
    var leftDepthPrev: Float = 0.0
    var rightDepthPrev: Float = 0.0
    var depthAll: [[Float]] = []
    var defDepth: Float = 0.0
    
    var heightAll: [Float] = []
    
    //Eye Glance用
    var normalizedLeftIris: [CGPoint] = []
    var normalizedRightIris: [CGPoint] = []
    
    var leftIrisPrev =  CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    var rightIrisPrev = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    
    var glanceFlag: Int = 0
    var glanceFirstPoint: Int = 0
    var distGlanceNum: Int = 0
    
    var firstDirect: CGFloat = 0.0
    var firstDirectIris = lrPoint(l: CGFloat(0.0), r: CGFloat(0.0))
    var secondDirect: CGFloat = 0.0
    var secondDirectIris = lrPoint(l: CGFloat(0.0), r: CGFloat(0.0))
    
    var glanceResult: Int = 0
    
    var relativeDistance_x = lrPoint(l: 0.0, r: 0.0)
    var relativeDistance_xPrev = lrPoint(l: 0.0, r: 0.0)
    var refPointPrev = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    
    var leftInnerWhitePrev: CGFloat = 0.0
    var leftOuterWhitePrev: CGFloat = 0.0
    var rightInnerWhitePrev: CGFloat = 0.0
    var rightOuterWhitePrev: CGFloat = 0.0
    
    //短すぎて初期化した時のフレーム（wink, brink, glance共通）
    var distInitNum: Int = 0
    
    /////// ここから下はランドマークポイント ///////
    let screenWidth = UIScreen.main.bounds.width // (390.0)
    let screenHeight = UIScreen.main.bounds.height // (844.0)
    
    var circleLayer: CAShapeLayer?
    var rectLayer: CAShapeLayer?
    
    var tapCount = 0
    let imageSizeList = [(150, 126), (225, 189)]
    //    let imagePositionList = [(195.0, 204.0), (195.0, 704.0)]
    let cursorPointList = [6, 1]
    let lineWidthList = [2.0, 1.5, 1.0]
    
    var inputCharacter = ""
    /////// ここまでがランドマークポイント ///////
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.setSampleBufferDelegate(self)
        camera.start()
        tracker.startGraph()
        tracker.delegate = self
        
        imageview.translatesAutoresizingMaskIntoConstraints = false
        imageview.contentMode = .scaleAspectFill
        
        NSLayoutConstraint.activate([
            imageview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageview.topAnchor.constraint(equalTo: view.topAnchor),
            imageview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 入力画面デザインの初期位置
        //        design1.center = CGPoint(x: CGFloat(imagePositionList[1].0), y: CGFloat(imagePositionList[1].1))
        // 入力画面ドラッグ
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        imputDesignImage.addGestureRecognizer(panGesture)
        imputDesignImage.isUserInteractionEnabled = true
        
        //ダブルタップで大きさ変更
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        imputDesignImage.isUserInteractionEnabled = true
        imputDesignImage.addGestureRecognizer(doubleTapGesture)
        
        updateImageViewSize()
        
        inputLabel.layer.borderWidth = 0.5
        inputLabel.text = ""
        questionLabel.layer.borderWidth = 0.5
        questionLabel.text = "な"
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        tracker.processVideoFrame(pixelBuffer)
        
        frameNum += 1
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer!))
            self.frameLabel.text = "\(self.frameNum)"
        }
    }
    
    func irisTracker(_ irisTracker: SYIris!, didOutputLandmarks landmarks: [Landmark]!) {
  // 全ランドマーク取得
        var landmarkAll : [[Float]] = []
        if let unwrapped = landmarks {
            for (point) in unwrapped {
                landmarkAll.append([point.x, point.y])
            }
            
  // 領域選択カーソルの処理
            // 正規化した鼻の位置の取得
            let normalizedNosePoint = normalizedLandmarkPoint(point: landmarkAll[cursorPointList[1]])
            let nosePoint = CGPoint(x: normalizedNosePoint.x * screenWidth, y: normalizedNosePoint.y * screenHeight)
            
            //カーソル描画
            DispatchQueue.main.async {
                self.drawCursor(point: nosePoint)
            }
            
            // 位置が変わった時のフィードバック用バイブレーション
            let feedbackGenerator = UISelectionFeedbackGenerator()
            
            let areaChangeFlnag = LandmarkPositionSerect(point: nosePoint)
            if areaChangeFlnag == 1 {
                feedbackGenerator.selectionChanged()
            }
            
  // Depthの計算・表示
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
            
            let leftIrisSize = caluclateIrisDiamater(landmark: leftEyeLandmark, imageSize: [WIDTH, HEIGHT])
            let rightIrisSize = caluclateIrisDiamater(landmark: rightEyeLandmark, imageSize: [WIDTH, HEIGHT])
            
            let leftDepth_mm = caluclateDepth(centerPoint: leftEyeLandmark[0] , focalLength: FOCAL_LENGTH, irisSize: leftIrisSize, width: WIDTH, height: HEIGHT)
            let rightDepth_mm = caluclateDepth(centerPoint: rightEyeLandmark[0], focalLength: FOCAL_LENGTH, irisSize: rightIrisSize, width: WIDTH, height: HEIGHT)
            
            DispatchQueue.main.async {
                self.leftLavel.text = "\(Int(round(leftDepth_mm / 10)))"
                self.rightLabel.text = "\(Int(round(rightDepth_mm / 10)))"
            }
            
  //Eye Glance用データ
            //irisの正規化
            let normalizedLeftIris: [CGPoint] = normalizeLandmarks(leftEyeLandmark)
            let normalizedRightIris: [CGPoint] = normalizeLandmarks(rightEyeLandmark)
            
            //  y方向
            let leftIrisDiff_y = normalizedLeftIris[0].y - leftIrisPrev.y
            let rightIrisDiff_y = normalizedRightIris[0].y - rightIrisPrev.y
            
            // x方向
            let leftIrisDiff_x = normalizedLeftIris[0].x - leftIrisPrev.x
            let rightIrisDiff_x = normalizedRightIris[0].x - rightIrisPrev.x
            
  // Wink・brink用データ
            // 瞼の高さ
            leftEyelidHeight = getLandmerkLength(point0: landmarkAll[159], point1: landmarkAll[145], imageSize: [WIDTH, HEIGHT])
            rightEyelidHeight = getLandmerkLength(point0: landmarkAll[386], point1: landmarkAll[374], imageSize: [WIDTH, HEIGHT])
            
            // 1フレーム前の瞼の高さとの差分値
            leftEyelidDiff = leftEyelidHeight - leftPrev
            rightEyelidDiff = rightEyelidHeight - rightPrev
            
            // 左右の高さの差
            lrHeightDiff = leftEyelidHeight - rightEyelidHeight
            
            // 左右の1フレーム前との差分値の差
            lrDiff = leftEyelidDiff - rightEyelidDiff
            
            // 左右の高さの差を5フレーム分記録
            heightAll.insert(lrHeightDiff, at: 0)
            var heightAvg5: Float = 0
            if (heightAll.count >= 8) {
                for i in (0 ..< 5) {
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
            
  // 判別
            // brink判別
            let brinkIkichi = brinkDitect()
            
            // Eye Glance判別
            let eyeWave = eyeGlanceDitect(leftY: leftIrisDiff_y, rightY: rightIrisDiff_y, leftX: leftIrisDiff_x, rightX: rightIrisDiff_x)
            
            // wink判別
            let wink = winkDitect()
            
            // 実験用入力判別
            judgment()
            
  // 入力が起こったフレームの出力用
            var printWinkFrame: Int = 0
            var printBrinkFrame: Int = 0
            var printGlanceFrame: Int = 0
            var printInitFrame: Int = 0
            if (distWinkNum == frameNum) {
                printWinkFrame = distWinkNum
            }
            if (distBrinkNum == frameNum) {
                printBrinkFrame = distBrinkNum
            }
            if (distGlanceNum == frameNum) {
                printGlanceFrame = distGlanceNum
            }
            if (distInitNum == frameNum) {
                printInitFrame = distInitNum
            }
            
            
  //実験データ出力
//            print("\(frameNum), \(inputCharacter), \(printInputCountCha), \(successTimer), \(firstInput), \(inputCountAll), \(String(format: "%.3f", judgeRatioAll)), \(frameNum), \(leftEyelidHeight), \(rightEyelidHeight), \(defDepth / 10.0), \(leftEyelidDiff), \(rightEyelidDiff), \(brinkIkichi), \(Double(brinkFlag) * 4.5), \(frameNum), \(lrHeightDiff), \(lrDiff), \(wink.WINK_IKITCH_MIN), \(wink.WINK_IKITCH_MAX), \(winkFlag * 5), \(printWinkFrame), \(printBrinkFrame), \(moveMissjudgeFlag)")
            //            print("\(frameNum), \(leftIrisDiff_y), \(rightIrisDiff_y), \(frameNum), \(glanceDist), \(glanceFlag), \(glanceFirstPoint), \(printGlanceFrame), \(brinkFlag),  \(printBrinkFrame), \(printInitFrame), \(frameNum), \(leftIrisDiff_x), \(rightIrisDiff_x), \(normalizedLeftIris[0].x), \(refPoint.x), \(refPointDiff), \(relativeDistance_x.l), \(relativeDistance_x.r), \(relativeDistanceLeftDiff), \(relativeDistanceRightDiff), \(frameNum), \(leftInnerWhite), \(leftOuterWhite), \(rightInnerWhite), \(rightOuterWhite), \(frameNum), \(leftInnerWhiteDiff), \(leftOuterWhiteDiff), \(rightInnerWhiteDiff), \(rightOuterWhiteDiff)")
            //            print("\(frameNum), \(leftIrisDiff_y), \(rightIrisDiff_y), \(frameNum), \(glanceDist), \(glanceFlag), \(glanceFirstPoint), \(printGlanceFrame), \(brinkFlag),  \(printBrinkFrame), \(printInitFrame), \(frameNum), \(leftIrisDiff_x), \(rightIrisDiff_x), \(directionDist), \(firstDirect), \(secondDirect), \(firstDirectIris.l), \(firstDirectIris.r), \(secondDirectIris.l), \(secondDirectIris.r), \(glanceResult)")
            print("\(frameNum), \(leftIrisDiff_y), \(rightIrisDiff_y), \(eyeWave.glanceDist), \(round(glanceUpSliderValue*10)/10), \(round(glanceDownSliderValue*10)/10), \(glanceFlag), \(glanceFirstPoint), \(printGlanceFrame), \(brinkFlag),  \(printBrinkFrame), \(printInitFrame), \(frameNum), \(leftIrisDiff_x), \(rightIrisDiff_x), \(eyeWave.directionDist),  \(firstDirect), \(secondDirect), \(glanceResult)")
            
            
            
  // ↓ここから下：次のフレームで使用する現在の値を保存・初期化
            leftPrev = leftEyelidHeight
            rightPrev = rightEyelidHeight
            
            lrDiffPrev = lrDiff
            
            leftDepthPrev = leftDepth_mm
            rightDepthPrev = rightDepth_mm
            
            leftIrisPrev = normalizedLeftIris[0]
            rightIrisPrev = normalizedRightIris[0]
            
            //　glance確認用
            if (frameNum - distGlanceNum > 4) {
                DispatchQueue.main.async {
                    self.movementLabel.text = "___"
                }
                glanceResult = 0
            }
            
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
            
            // winkが右か左か判別して色付けするやつ
            inputLabelFlag = 0
            
            if (moveMissjudgeFlag == 1) {
                moveMissjudgeFlag = 0
            }
            
            inputCharacter = ""
            successTimer = 0
            printInputCountCha = 0
        }
    }
    
    
    // 設定画面遷移ボタン 画面キャプチャを止める
    @IBAction func settingButtonPush(_ sender: Any) {
        camera.stop()
    }
    
    // 設定画面から戻る時の処理
    func restartCapture() {
        camera.start()
        
        frameNum = 0
        allInit()
    }
    
    func irisTracker(_ irisTracker: SYIris!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        // キャプチャにランドマークを描画
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
        }
    }
}

