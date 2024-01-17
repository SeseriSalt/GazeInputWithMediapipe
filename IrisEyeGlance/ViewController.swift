//
//  ViewController.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2022/10/12.
//

import UIKit
import AVFoundation

// 右左の構造体
struct lrPoint {
    var l: CGFloat = 0.0
    var r: CGFloat = 0.0
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, SYIrisDelegate {
    
    
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var frameLabel: UILabel!
    @IBOutlet weak var leftLavel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    @IBOutlet weak var firstPeak: UILabel!
    @IBOutlet weak var secondPeak: UILabel!
    @IBOutlet weak var lateFlagLabel: UILabel!
    
    @IBOutlet weak var inputLabel: UILabel!
    @IBOutlet weak var inputDesignImage: UIImageView!
    @IBOutlet weak var consonantDesignImage: UIImageView!
    
    @IBOutlet weak var ISCenterLabel: UILabel!
    @IBOutlet weak var ISWidthLabel: UILabel!
    
    @IBOutlet weak var questionLabel: UILabel!
    
    @IBOutlet weak var movementLabel: UILabel!
    
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var createCSVButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    
    @IBOutlet weak var calibrationButton: UIButton!
    @IBOutlet weak var calibrationCommentLabel: UILabel!
    @IBOutlet weak var calibrationCenterLabel: UILabel!
    
    var pushTimes: Int = -1
    
    // [[maxBig1, minBig1], [maxBig2, minBig2], [maxSmall1, minSmall1], [maxSmall2, minSmall2], [maxBig3, minBig3], [maxBig4, minBig4], [maxSmall3, minSmall4], [maxSmall3, minSmall4]]
    var dataArray20: [[CGFloat]] = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
    var dataArray30: [[CGFloat]] = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
    var dataArray40: [[CGFloat]] = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
    
    // [max0.85傾き, max0.85切片, min0.85傾き, min0.85切片, max1.4傾き, max1.4切片, min1.4傾き, min1.4切片]
    var eyeGlanceThBig: [CGFloat] = UserDefaults.standard.object(forKey: "eyeGlanceThBig") as? [CGFloat] ?? [-0.20858237022685178, 11.751121972836446, 0.10891677755024035, -8.016162924026247, -0.49078204759259353, 27.649698759615205, 0.2562747707064477, -18.86155982123822]
    var eyeGlanceThSmall: [CGFloat] = UserDefaults.standard.object(forKey: "eyeGlanceThSmall") as? [CGFloat] ?? [-0.06204727680720945, 3.9551389589382233, 0.0750861886227195, -4.825069320151132, -0.16545940481922494, 10.547037223835256, 0.20022983632725186, -12.866851520403012]
    
    
    let camera = Camera()
    let tracker: SYIris = SYIris()!
    
    var recFlag: Int = 0
    var fileName: String = ""
    
    public let FOCAL_LENGTH: Float = 1304.924438
    public let WIDTH: Float = 1080.0
    public let HEIGHT: Float = 1920.0
    public var frameNum: Int = 0
    
    // Wink用
    var leftEyelidHeight: Float = 0.0
    var rightEyelidHeight: Float = 0.0
    var leftEyelidDiff: Float = 0.0
    var rightEyelidDiff: Float = 0.0
    var leftEyelidHeightPrev: Float = 0.0
    var rightEyelidHeightPrev: Float = 0.0
    var lrHeightDiff: Float = 0.0
    var lrDiff: Float = 0.0
    var lrDiffPrev: Float = 0.0
    
    var leftDepthPrev: Float = 0.0
    var rightDepthPrev: Float = 0.0
    var depthAll: [[Float]] = []
    var defDepth: Float = 0.0
    var heightAvg5: Float = 0
    var heightAll: [Float] = []
    
    //Eye Glance用
    lazy var leftEye = EyeData()
    lazy var rightEye = EyeData()
    
    
    // 閾値
    var winkIkichiMax: Float = 0.0
    var winkIkichiMin: Float = 0.0
    var winkIkichiHeight: Float = 0.0
    var brinkIkichi: Float = 0.0
    var winkIkichiMaxNext: Float = 0.0
    var winkIkichiMinNext: Float = 0.0
    var heightIkichiNext: Float = 0.0
    var brinkIkichNext: Float = 0.0
    
    var glanceIkichiMaxBig: CGFloat = 0.0
    var glanceIkichiMinBig: CGFloat = 0.0
    var ikichiAreaUpBig: CGFloat = 0.0
    var ikichiAreaDownBig: CGFloat = 0.0
    var glanceIkichiMaxSmall: CGFloat = 0.0
    var glanceIkichiMinSmall: CGFloat = 0.0
    var ikichiAreaUpSmall: CGFloat = 0.0
    var ikichiAreaDownSmall: CGFloat = 0.0

    
    // 選択領域が起こったフレーム
    var areaChangeFrame = 0
    
    //短すぎて初期化した時のフレーム（wink, glance）
    var distWinkInitNum: Int = 0
    var distGlanceInitNum: Int = 0
    
    //カットオフに関するパラメータ
    let SAMPLE_RATE = 30.0 // 30fps
    let CUTOFF_FREQUENCY = 4.0 // 4Hz
    // フィルタのインスタンス
    lazy var lowPassFilterX = LowPassFilter(cutoffFrequency: CUTOFF_FREQUENCY, sampleRate: SAMPLE_RATE)
    lazy var lowPassFilterY = LowPassFilter(cutoffFrequency: CUTOFF_FREQUENCY, sampleRate: SAMPLE_RATE)
    
    /////// ここから下はランドマークポイント ///////
    let screenWidth = UIScreen.main.bounds.width // (390.0)
    let screenHeight = UIScreen.main.bounds.height // (844.0)
    
    var circleLayer: CAShapeLayer?
    var rectLayer: CAShapeLayer?
    
    var tapCount = 0
    let imageSizeList = [(175, 147), (200, 168), (150, 126)]
    let imageSizeListCon = [(87, 73), (127, 106), (75, 63)]
    let CURSOR_LANDMARK: Int = 1
    let IMAGE_INITISL_POSITION = CGPoint(x: 195.0, y: 422.0)
    let lineWidthList = [1.5, 1.5, 1.25]
    
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
        
        let symbolImage = UIImage(systemName: "record.circle")
        createCSVButton.setImage(symbolImage, for: .normal)
        
        // 入力画面デザインの初期位置
        inputDesignImage.center = IMAGE_INITISL_POSITION
        // 入力画面ドラッグ
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        inputDesignImage.addGestureRecognizer(panGesture)
        inputDesignImage.isUserInteractionEnabled = true
        
        //ダブルタップで大きさ変更
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        inputDesignImage.isUserInteractionEnabled = true
        inputDesignImage.addGestureRecognizer(doubleTapGesture)
        
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
            let normalizedNosePoint = normalizedLandmarkPoint(point: landmarkAll[CURSOR_LANDMARK])
            let nosePoint = CGPoint(x: normalizedNosePoint.x * screenWidth, y: normalizedNosePoint.y * screenHeight)
            
            //カーソル描画
            DispatchQueue.main.async {
                self.drawCursor(point: nosePoint)
            }
            
            // 位置が変わった時のフィードバック用バイブレーション
            let feedbackGenerator = UISelectionFeedbackGenerator()
            
            let (areaChangeFlag, areaChangeFrame) = LandmarkPositionSerect(point: nosePoint)
            if areaChangeFlag == 1 {
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
            // irisの正規化
            leftEye.landmarks = normalizeLandmarks(leftEyeLandmark)
            rightEye.landmarks = normalizeLandmarks(rightEyeLandmark)
            
            // 基準点
            let refPoint = CGPoint(x: CGFloat((landmarkAll[193][0] + landmarkAll[168][0] + landmarkAll[417][0]) / 3), y: CGFloat((landmarkAll[193][1] + landmarkAll[168][1] + landmarkAll[417][1]) / 3))
            // ローパスフィルタ
            let filteredRefPoint = CGPoint(x: lowPassFilterX.filter(value: refPoint.x), y: lowPassFilterY.filter(value: refPoint.y))
            
            leftEye.refPoint = filteredRefPoint
            rightEye.refPoint = filteredRefPoint
            
//            let refPointdist = sqrt(leftEye.refPointDiff2().x * leftEye.refPointDiff2().x + leftEye.refPointDiff2().y * leftEye.refPointDiff2().y)
            
  // Wink・brink用データ
            // 瞼の高さ
            leftEyelidHeight = getLandmerkLength(point0: landmarkAll[159], point1: landmarkAll[145], imageSize: [WIDTH, HEIGHT])
            rightEyelidHeight = getLandmerkLength(point0: landmarkAll[386], point1: landmarkAll[374], imageSize: [WIDTH, HEIGHT])
            
            // 1フレーム前の瞼の高さとの差分値
            leftEyelidDiff = leftEyelidHeight - leftEyelidHeightPrev
            rightEyelidDiff = rightEyelidHeight - rightEyelidHeightPrev
            
            // 左右の高さの差
            lrHeightDiff = leftEyelidHeight - rightEyelidHeight
            
            // 左右の1フレーム前との差分値の差
            lrDiff = leftEyelidDiff - rightEyelidDiff
            
            // 左右の高さの差を5フレーム分記録
            heightAll.insert(lrHeightDiff, at: 0)
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
            if depthAll.count > 5 {
                defDepth = depthAll.last![0]
                depthAll.removeFirst()
            }
            
  // キャリブレーション中の処理
            if pushTimes != -1 {
                getCalibrationData(left: leftEye.irisNoseDiff2(), right: rightEye.irisNoseDiff2(), refDiff: leftEye.refPointDiff2())
            }
            
  // 判別
            // 閾値の決定
            let ikichi = ikichiDecision(depth: defDepth) //// ????なんで5フレーム前のdepth使ってる？
            
            // brink判別
            let brink = brinkDitect()
            
            // wink判別
            let wink = winkDitect()
            
            // Eye Glance判別
            let eyeWave = eyeGlance(left: leftEye.irisNoseDiff2(), right: rightEye.irisNoseDiff2(), refDiff: leftEye.refPointDiff2(), ikichi: (maxBig: glanceIkichiMaxBig, minBig: glanceIkichiMinBig, maxSmall: glanceIkichiMaxSmall, minSmall: glanceIkichiMinSmall, areaupBig: ikichi.areaUpBig, areadownBig: ikichi.areaDownBig, areaupSmall: ikichi.areaUpSmall, areadownSmall: ikichi.areaDownSmall))
            
            // 実験用入力判別
            judgment()
            
  // 入力が起こったフレームの出力用
            let printWinkFrame = distWinkNum == frameNum ? String(distWinkNum) : ""
            let printBrinkFrame = distBrinkNum == frameNum ? String(distBrinkNum) : ""
            let printGlanceFrame = distGlanceNum == frameNum ? String(distGlanceNum) : ""
            let printWinkInitFrame = frameNum - distWinkInitNum <= 4 ? String(distWinkInitNum) : ""
            let printGlanceInitFrame = frameNum - distGlanceInitNum <= 4 ? String(distGlanceInitNum) : ""
            
//実験データ出力
            //矢田さんの出力
//            let output = "\(frameNum), \(inputCharacter), \(printInputCountCha), \(successTimer), \(firstInputFlag), \(inputCountAll), \(String(format: "%.3f", judgeRatioAll)), \(leftEyelidDiff), \(rightEyelidDiff), \(defDepth / 10.0), \(lrHeightDiff), \(lrDiff), \(wink.WINK_IKITCH_MIN), \(wink.WINK_IKITCH_MAX), \(winkFlag * 5), \(printWinkFrame), \(moveMissjudgeFlag), \(printWinkInitFrame), \(brink), \(Double(brinkFlag) * 4.5), \(printBrinkFrame), \(printGlanceInitFrame), \(leftIrisDiff_y), \(rightIrisDiff_y), \(eyeWave.glanceDist), \(ikichi.glanceMax), \(ikichi.glanceMin), \(glanceFlag), \(glanceFirstPoint), \(printGlanceFrame), \(leftIrisDiff_x), \(rightIrisDiff_x), \(eyeWave.directionDist),  \(firstDirect), \(secondDirect), \(inputResult)"

//            var indices = Array(468...477)
//            indices.append(contentsOf: [45, 1, 275, 5, 4, 1])
            
//            var variableNames = """
//              frameNum, lrDepthDiff, brink, brinkFirstPoint, distBrinkNum, brinkFlag, normalizedLeft[0].x, normalizedLeft[0].y, normalizedRight[0].x, normalizedRight[0].y, refpointX, refpointY, filteredRefPoint.x, filteredRefPoint.y, filteredRefPointDiff.x, filteredRefPointDiff.y, leftEyeNose2Diff.x,leftEyeNose2Diff.y, rightEyeNose2Diff.x, rightEyeNose2Diff.y,
//"""
            var variableNames = """

"""
            
            variableNames += """
questionCharacter, inputCharacter, areaChangeFrame, changePositionFlag, printInputCountCha, successTimer, firstInputFlag, inputCountAll, judgeRatioAll, leftEyelidDiff, rightEyelidDiff, defDepth/10.0, lrHeightDiff, lrDiff, wink.WINK_IKITCH_MIN, wink.WINK_IKITCH_MAX, winkFlag*5, printWinkFrame, moveMissjudgeFlag, printWinkInitFrame, brink, brinkFlag*4.5, printBrinkFrame, printGlanceInitFrame, leftIrisDiff_y, rightIrisDiff_y, eyeWave.glanceDist, ikichi.glanceMax, ikichi.glanceMin, areaDown, areaUp, endFrame, ikichi.areaUp, ikichi.areaDown, glanceFlag, glanceFirstPoint, printGlanceFrame, leftIrisDiff_x, rightIrisDiff_x, eyeWave.directionDist, inputResult, arrayAreaUp[0].frame, arrayAreaUp[1].frame, arrayAreaUp[2].frame, arrayAreaUp[0].area, arrayAreaUp[1].area, arrayAreaUp[2].area, directUp, directIrisUp.l, directIrisUp.r, arrayAreaDown[0].frame, arrayAreaDown[1].frame, arrayAreaDown[2].frame, arrayAreaDown[0].area, arrayAreaDown[1].area, arrayAreaDown[2].area, directDown, directIrisDown.l, directIrisDown.r,
"""

              
//              var header = ""
//              for index in indices {
//                  header += "x\(index), y\(index), "
//              }
//              header = String(header.dropLast(2))  // 最後のカンマとスペースを削除
////              ランドマークとその他のヘッダー名を結合
//              variableNames += header
//            if(frameNum == 202){
//              if arrayAreaUp.count > 3 && arrayAreaDown.count > 3{
//                  print("-------------------------------------------------------------------------------------------------------")
//                  print(variableNames)
//              }
//
//          }
//            print(variableNames)
            
            
            var output = "\(frameNum), \(lrDepthDiff), \(brink), \(brinkFirstFrame), \(distBrinkNum), \(brinkFlag), \(leftEye.landmarks[0].x), \(leftEye.landmarks[0].y), \(rightEye.landmarks[0].x), \(rightEye.landmarks[0].y), \(refPoint.x), \(refPoint.y), \(filteredRefPoint.x), \(filteredRefPoint.y), \(leftEye.refPointDiff().x), \(rightEye.refPointDiff().y), \(leftEye.irisNoseDiff2().x), \(leftEye.irisNoseDiff2().y), \(rightEye.irisNoseDiff2().x), \(rightEye.irisNoseDiff2().y),"

            
//            if arrayAreaUp.count > 3 && arrayAreaDown.count > 3{
//                output += "\(questionCharacter), \(inputCharacter), \(areaChangeFrame), \(changePositionFlag), \(printInputCountCha), \(successTimer), \(firstInputFlag), \(inputCountAll), \(String(format: "%.3f", judgeRatioAll)), \(leftEyelidDiff), \(rightEyelidDiff), \(defDepth / 10.0), \(lrHeightDiff), \(lrDiff), \(wink.WINK_IKITCH_MIN), \(wink.WINK_IKITCH_MAX), \(winkFlag*5), \(printWinkFrame), \(moveMissjudgeFlag), \(printWinkInitFrame), \(brink), \(Double(brinkFlag) * 4.5), \(printBrinkFrame), \(printGlanceInitFrame), \(leftEye.irisDiff().y), \(rightEye.irisDiff().y), \(eyeWave.glanceDist), \(ikichi.glanceMax), \(ikichi.glanceMin), \(areaDown), \(areaUp), \(glanceEndFrame), \(ikichi.areaUp), \(ikichi.areaDown), \(glanceFlag), \(glanceFirstFrame), \(printGlanceFrame), \(leftEye.irisDiff().x), \(rightEye.irisDiff().x), \(eyeWave.directionDist),  \(inputResult), \(arrayAreaUp[0].frame), \(arrayAreaUp[1].frame), \(arrayAreaUp[2].frame), \(arrayAreaUp[0].area), \(arrayAreaUp[1].area), \(arrayAreaUp[2].area), \(directUp), \(directIrisUp.l), \(directIrisUp.r), \(arrayAreaDown[0].frame), \(arrayAreaDown[1].frame), \(arrayAreaDown[2].frame), \(arrayAreaDown[0].area), \(arrayAreaDown[1].area), \(arrayAreaDown[2].area), \(directDown), \(directIrisDown.l), \(directIrisDown.r),"
//            }
//            var data = ""
//            for index in indices {
//                let x = landmarkAll[index][0]
//                let y = landmarkAll[index][1]
//                data += "\(x), \(y), "
//            }
//            data = String(data.dropLast(2))  // 最後のカンマとスペースを削除
//            
//            output += data
            
//            output += "\(leftEye.landmarks[0].x), \(leftEye.landmarks[0].y), \(rightEye.landmarks[0].x), \(rightEye.landmarks[0].y), \(leftEye.refPoint.x), \(rightEye.refPoint.y), \(leftEye.refPointDiff().x), \(rightEye.refPointDiff().y), \(leftEye.irisNoseDiff2().x), \(leftEye.irisNoseDiff2().y), \(rightEye.irisNoseDiff2().x), \(rightEye.irisNoseDiff2().y)"
            
            // コンソール出力
//            if arrayAreaUp.count > 3 && arrayAreaDown.count > 3{
//                print(output)
//            }
//            print(output)
            
            let aadFrame: Any = arrayAreaDown.count == 0 ? "" : arrayAreaDown[0].frame
            let aadArea: Any  = arrayAreaDown.count == 0 ? "" : arrayAreaDown[0].area
            let aauFrame: Any  = arrayAreaUp.count == 0 ? "" : arrayAreaUp[0].frame
            let aauArea: Any  = arrayAreaUp.count == 0 ? "" : arrayAreaUp[0].area
            
            // データの出力
            func printVariablesAsCSV(_ variables: Any...) {
                let values = variables.map { "\($0)" }.joined(separator: ", ")
                print(values)
            }
            
            let HEADER = "frameNum, defDepth, inputCharacter, eyeWave.glanceDist, eyeWave.correctionValue, areaChangeFlag * 10, ikichi.glanceMaxSmall, ikichi.glanceMinSmall, areaChangeFrame, areaDown, ikichi.areaDownBig, ikichi.areaDownSmall, aadFrame, aadArea, arrayAreaDown.count, glanceDownNext, glanceFlag, areaUp, ikichi.areaUpBig, ikichi.areaUpSmall, aauFrame, aauArea, arrayAreaUp.count, glanceUpNext, directDown, directUp"
//            if frameNum == 101 {
//                print("\n\n---------------------------------------------------------------------------------------------")
//                print(HEADER)
//            }
            // データの出力　引数そのままコピペしたらヘッダになる
            switch pushTimes {
            case 0, 9, 18, 27, 28, 29:
                break
            default:
                printVariablesAsCSV(frameNum, defDepth, inputCharacter, eyeWave.glanceDist, eyeWave.correctionValue, areaChangeFlag * 10, ikichi.glanceMaxSmall, ikichi.glanceMinSmall, areaChangeFrame, areaDown, ikichi.areaDownBig, ikichi.areaDownSmall, aadFrame, aadArea, arrayAreaDown.count, glanceDownNext, glanceFlag, areaUp, ikichi.areaUpBig, ikichi.areaUpSmall, aauFrame, aauArea, arrayAreaUp.count, glanceUpNext, directDown, directUp)
            }
            
            if recFlag == 1 {
                // CSVファイルにデータを追記
                appendDataToCSVFile(data: output + "\n")
            }
            
            
  // ↓ここから下：次のフレームで使用する現在の値を保存・初期化
            leftEyelidHeightPrev = leftEyelidHeight
            rightEyelidHeightPrev = rightEyelidHeight
            
            lrDiffPrev = lrDiff
            
            leftDepthPrev = leftDepth_mm
            rightDepthPrev = rightDepth_mm
            
            glanceDistPrev = eyeWave.glanceDist
            
            leftEye.storeData()
            rightEye.storeData()
            
            //　glance確認用
            if (frameNum - distGlanceNum > 4 && frameNum - distWinkNum > 4 && frameNum - distBrinkNum > 4) {
                DispatchQueue.main.async {
                    self.movementLabel.text = "___"
                }
                inputResult = 0
            }
            
            // フラグが立っていない時のみ閾値を更新（フラグが立っている時、閾値はフラグが立ったフレームの値）
            if (winkFlag == 0) {
                winkIkichiMax = winkIkichiMaxNext
                winkIkichiMin = winkIkichiMinNext
                winkIkichiHeight = heightIkichiNext
            }
            
            if (brinkFlag == 0) {
                brinkIkichi = brinkIkichNext
                
                if (winkFlag == 0) {
                    // 瞬きの時はwinkも止める
                    winkIkichiMax = winkIkichiMaxNext
                    winkIkichiMin = winkIkichiMinNext
                    winkIkichiHeight = heightIkichiNext
                }
            }
            
            if (glanceFlag == 0) {
                glanceIkichiMaxBig = ikichi.glanceMaxBig
                glanceIkichiMinBig = ikichi.glanceMinBig
                glanceIkichiMaxSmall = ikichi.glanceMaxSmall
                glanceIkichiMinSmall = ikichi.glanceMinSmall
                ikichiAreaUpBig = ikichi.areaUpBig
                ikichiAreaDownBig = ikichi.areaDownBig
                ikichiAreaUpSmall = ikichi.areaUpSmall
                ikichiAreaDownSmall = ikichi.areaDownSmall
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
    
    func appendDataToCSVFile(data: String) {
        let fileManager = FileManager.default
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName, isDirectory: false)
        
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: [:])
        }
        else {
            do {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data.data(using: .utf8)!)
                fileHandle.closeFile()
            } catch {
                print("Error writing to file: \(error)")
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    @IBAction func resetButtonPush(_ sender: UIButton) {
        inputInit()
        frameNum = 0
        distBrinkNum = 0
        distWinkNum = 0
        distGlanceInitNum = 0
        distWinkInitNum = 0
        distGlanceNum = 0
        allInit()
    }
    
    @IBAction func createCSVButtonPush(_ sender: UIButton) {
        // ボタンの表示変更
        if recFlag == 0 {
            let currentTime = getCurrentTime()
            fileName = "\(currentTime).csv"
            sender.setTitle("停止", for: .normal)
            sender.setTitleColor(.red, for: .normal)
            let symbolImage = UIImage(systemName: "stop.circle")
            sender.setImage(symbolImage, for: .normal)
            sender.tintColor = .red
            recFlag = 1
        } else {
            sender.setTitle("データ取得", for: .normal)
            sender.setTitleColor(.blue, for: .normal)
            let symbolImage = UIImage(systemName: "record.circle")
            sender.setImage(symbolImage, for: .normal)
            sender.tintColor = .blue
            recFlag = 0
        }
    }
    
    func getCurrentTime() -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            return formatter.string(from: Date())
        }
    
    // 設定画面遷移ボタン 画面キャプチャを止める
    @IBAction func settingButtonPush(_ sender: Any) {
        camera.stop()
    }
    
    @IBAction func calibrationButtonPush(_ sender: UIButton) {
        pushTimes += 1
        
        switch pushTimes {
        case 0:
            calibrationCommentLabel.text = "鼻を+に合わせて\n距離を20cmくらいに調整してね↓"
            calibrationCenterLabel.text = "＋"
            sender.setTitle("スタート", for: .normal)
            inputDesignImage.center = CGPoint(x: 1000.0, y: 1000.0)
            
            
        case 1, 5, 10, 14, 19, 23:
            calibrationCommentLabel.text = ""
            calibrationCenterLabel.text = "↖︎"
            sender.setTitle("次へ", for: .normal)
            if pushTimes == 1 {
                print("\n\n----------------------------------------------------")
                print("キャリブレーション20開始:\(frameNum)")
                print("----------------------------------------------------\n\n")
            }
            if pushTimes == 10 {
                print("\n\n----------------------------------------------------")
                print("キャリブレーション30開始:\(frameNum)")
                print("----------------------------------------------------\n\n")
            }
            if pushTimes == 19 {
                print("\n\n----------------------------------------------------")
                print("キャリブレーション40開始:\(frameNum)")
                print("----------------------------------------------------\n\n")
            }
            
        case 2, 6, 11, 15, 20, 24:
            calibrationCenterLabel.text = "↗︎"
            
        case 3, 7, 12, 16, 21, 25:
            calibrationCenterLabel.text = "↙︎"
            
        case 4, 8, 13, 17, 22, 26:
            calibrationCenterLabel.text = "↘︎"
            
        case 9:
            calibrationCommentLabel.text = "鼻を+に合わせて\n距離を30cmくらいに調整してね↓"
            calibrationCenterLabel.text = "＋"
            sender.setTitle("スタート", for: .normal)
            print("\n\n----------------------------------------------------")
            print("キャリブレーション20終了:\(frameNum)")
            print("----------------------------------------------------\n\n")
            
        case 18:
            calibrationCommentLabel.text = "鼻を+に合わせて\n距離を40cmくらいに調整してね↓"
            calibrationCenterLabel.text = "＋"
            sender.setTitle("スタート", for: .normal)
            print("\n\n----------------------------------------------------")
            print("キャリブレーション30終了:\(frameNum)")
            print("----------------------------------------------------\n\n")
            
        case 29:
            calibrationCommentLabel.text = "これでバッチリ入力できます"
            calibrationCenterLabel.text = ""
            sender.setTitle("閉じる", for: .normal)
            UserDefaults.standard.set(eyeGlanceThBig, forKey: "eyeGlanceThBig")
            UserDefaults.standard.set(eyeGlanceThSmall, forKey: "eyeGlanceThSmall")
            
        case 30:
            calibrationCommentLabel.text = ""
            sender.setTitle("補正", for: .normal)
            inputDesignImage.center = CGPoint(x: 195.0, y: 422.0)
            pushTimes = -1
            
            
        default:
            break
        }
    }
    
    // 設定画面から戻る時の処理
    func restartCapture() {
        camera.start()
        
        frameNum = 0
        distBrinkNum = 0
        distWinkNum = 0
        distGlanceInitNum = 0
        distWinkInitNum = 0
        distGlanceNum = 0
        allInit()
    }
    
    func irisTracker(_ irisTracker: SYIris!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        // キャプチャにランドマークを描画
//        DispatchQueue.main.async {
//            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
//        }
    }
}

