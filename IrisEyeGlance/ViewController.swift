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
    
    @IBOutlet weak var resultLabel: UILabel!
    
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
    var filterdRefPointPrev: CGPoint = CGPoint(x: 0.0, y: 0.0)
    var refPointPrev: CGPoint = CGPoint(x: 0.0, y: 0.0)
    
    
    // 閾値
    var winkIkichiMax: Float = 0.0
    var winkIkichiMin: Float = 0.0
    var winkIkichiHeight: Float = 0.0
    var brinkIkichi: Float = 0.0
    var winkIkichiMaxNext: Float = 0.0
    var winkIkichiMinNext: Float = 0.0
    var heightIkichiNext: Float = 0.0
    var brinkIkichNext: Float = 0.0
    
    var glanceIkichiMax: CGFloat = 0.0
    var glanceIkichiMin: CGFloat = 0.0
    var ikichiAreaUp: CGFloat = 0.0
    var ikichiAreaDown: CGFloat = 0.0

    
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
        resultLabel.text = ""
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
            let refPoint = CGPoint(x: CGFloat((landmarkAll[45][0] + landmarkAll[1][0] + landmarkAll[275][0]) / 3), y: CGFloat((landmarkAll[5][1] + landmarkAll[4][1] + landmarkAll[1][1]) / 3))
            // ローパスフィルタ
            let filteredRefPoint = CGPoint(x: lowPassFilterX.filter(value: refPoint.x), y: lowPassFilterY.filter(value: refPoint.y))
            
            leftEye.refPoint = filteredRefPoint
            rightEye.refPoint = filteredRefPoint
            
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
            let eyeWave = eyeGlance(left: leftEye.irisNoseDiff2(), right: rightEye.irisNoseDiff2(), refDiff: leftEye.refPointDiff2(), ikichi: (max: glanceIkichiMax, min: glanceIkichiMin, areaup: ikichiAreaUp, areadown: ikichiAreaDown))
            
            // 実験用入力判別
            judgment()
            
  // 入力が起こったフレームの出力用
            let printWinkFrame = distWinkNum == frameNum ? String(distWinkNum) : ""
            let printBrinkFrame = distBrinkNum == frameNum ? String(distBrinkNum) : ""
            let printGlanceFrame = distGlanceNum == frameNum ? String(distGlanceNum) : ""
            let printWinkInitFrame = frameNum - distWinkInitNum <= 4 ? String(distWinkInitNum) : ""
            let printGlanceInitFrame = frameNum - distGlanceInitNum <= 4 ? String(distGlanceInitNum) : ""
            
//実験データ出力
            let aadFrame: Any = arrayAreaDown.count == 0 ? "" : arrayAreaDown[0].frame
            let aadArea: Any  = arrayAreaDown.count == 0 ? "" : arrayAreaDown[0].area
            let aauFrame: Any  = arrayAreaUp.count == 0 ? "" : arrayAreaUp[0].frame
            let aauArea: Any  = arrayAreaUp.count == 0 ? "" : arrayAreaUp[0].area
            
            // データの出力
            func printVariablesAsCSV(_ variables: Any...) {
                let values = variables.map { "\($0)" }.joined(separator: ", ")
                print(values)
                if recFlag == 1 {
                    // CSVファイルにデータを追記
                    appendDataToCSVFile(data: values + "\n")
                }
            }
            
            let HEADER = "frameNum, inputCharacter, printInputCountCha, successTimer, firstInputFlag, inputCountAll, judgeRatioAll, frameNum, leftEyelidDiff, rightEyelidDiff, defDepth / 10.0, lrHeightDiff, lrDiff, wink.WINK_IKITCH_MIN, wink.WINK_IKITCH_MAX, frameNum, winkAreaUp, winkAreaDown, wink.WINK_IKITCH_MIN * winkAreaTimes, wink.WINK_IKITCH_MAX * winkAreaTimes, winkFlag * 5, printWinkFrame, moveMissjudgeFlag, printWinkInitFrame, brink, Double(brinkFlag) * 4.5, printBrinkFrame, frameNum, printGlanceInitFrame, leftEye.irisDiff2().y, rightEye.irisDiff2().y, printGlanceFrame, inputCharacter,  defDepth / 10.0, frameNum, eyeWave.glanceDist, ikichi.glanceMaxSmall, ikichi.glanceMinSmall, eyeWave.correctionValue, glanceFlag, areaChangeFlag * 3, frameNum, areaDown, ikichi.areaDownSmall, areaUp, ikichi.areaUpSmall, frameNum, leftEye.irisDiff2().x, rightEye.irisDiff2().x, directDown, directUp, inputResult"
            if frameNum == 30 {
                print("\n\n---------------------------------------------------------------------------------------------")
                print(HEADER)
            }
            // データの出力　引数そのままコピペしたらヘッダになる
            switch pushTimes {
            case 0, 2, 11, 12, 13:
                break
            default:
                printVariablesAsCSV(frameNum, inputCharacter, printInputCountCha, successTimer, firstInputFlag, inputCountAll, String(format: "%.3f", judgeRatioAll), frameNum, leftEyelidDiff, rightEyelidDiff, defDepth / 10.0, lrHeightDiff, lrDiff, wink.WINK_IKITCH_MIN, wink.WINK_IKITCH_MAX, frameNum, winkAreaUp, winkAreaDown, wink.WINK_IKITCH_MIN * Float(winkAreaSliderValue), wink.WINK_IKITCH_MAX * Float(winkAreaSliderValue), winkUpFlag * 5, winkDownFlag * 5, printWinkFrame, moveMissjudgeFlag, printWinkInitFrame, brink, Double(brinkFlag) * 4.5, printBrinkFrame, frameNum, printGlanceInitFrame, leftEye.irisDiff2().y, rightEye.irisDiff2().y, printGlanceFrame, inputCharacter, defDepth / 10.0, frameNum, eyeWave.glanceDist, ikichi.glanceMax, ikichi.glanceMin, eyeWave.correctionValue, glanceUpFlag, glanceDownFlag, areaChangeFlag * 3, frameNum, areaDown, ikichi.glanceAreaDown, areaUp, ikichi.glanceAreaUp, frameNum, leftEye.irisDiff2().x, rightEye.irisDiff2().x, directDown, directUp, inputResult, frameNum, filteredRefPoint.y - filterdRefPointPrev.y, refPoint.y - refPointPrev.y)
            }
            
            
  // ↓ここから下：次のフレームで使用する現在の値を保存・初期化
            leftEyelidHeightPrev = leftEyelidHeight
            rightEyelidHeightPrev = rightEyelidHeight
            
            lrDiffPrev = lrDiff
            
            leftDepthPrev = leftDepth_mm
            rightDepthPrev = rightDepth_mm
            
            leftEye.storeData()
            rightEye.storeData()
            
            refPointPrev = refPoint
            filterdRefPointPrev = filteredRefPoint
            
            //　glance確認用
            if (frameNum - distGlanceNum > 4 && frameNum - distWinkNum > 4 && frameNum - distBrinkNum > 4) {
                DispatchQueue.main.async {
                    self.movementLabel.text = "___"
                }
                inputResult = 0
            }
            
            // フラグが立っていない時のみ閾値を更新（フラグが立っている時、閾値はフラグが立ったフレームの値）
            if (winkUpFlag == 0) {
                winkIkichiMin = winkIkichiMinNext
                winkIkichiHeight = heightIkichiNext
            }
            if (winkDownFlag == 0) {
                winkIkichiMax = winkIkichiMaxNext
                winkIkichiHeight = heightIkichiNext
            }
            
            if (brinkFlag == 0) {
                brinkIkichi = brinkIkichNext
                
                if (winkUpFlag == 0) {
                    winkIkichiMin = winkIkichiMinNext
                    winkIkichiHeight = heightIkichiNext
                }
                if (winkDownFlag == 0) {
                    winkIkichiMax = winkIkichiMaxNext
                    winkIkichiHeight = heightIkichiNext
                }
                if (glanceDownFlag == 0) {
                    glanceIkichiMin = ikichi.glanceMin
                    ikichiAreaDown = ikichi.glanceAreaDown
                }
                if (glanceUpFlag == 0) {
                    glanceIkichiMax = ikichi.glanceMax
                    ikichiAreaUp = ikichi.glanceAreaUp
                }
            }
            
            if (glanceDownFlag == 0) {
                glanceIkichiMin = ikichi.glanceMin
                ikichiAreaDown = ikichi.glanceAreaDown
            }
            if (glanceUpFlag == 0) {
                glanceIkichiMax = ikichi.glanceMax
                ikichiAreaUp = ikichi.glanceAreaUp
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
            sender.setTitle("Stop", for: .normal)
            sender.setTitleColor(.red, for: .normal)
            let symbolImage = UIImage(systemName: "stop.circle")
            sender.setImage(symbolImage, for: .normal)
            sender.tintColor = .red
            recFlag = 1
        } else {
            sender.setTitle("Data Aquisition", for: .normal)
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
            calibrationCommentLabel.text = "距離を30cmくらいに調整してね\nボタンを押して5秒間＋を見つめて，\n5秒くらい経ったらもう一回ボタンを押してね"
            calibrationCenterLabel.text = "＋"
            sender.setTitle("Start", for: .normal)
            inputDesignImage.center = CGPoint(x: 1000.0, y: 1000.0)
            
        case 1:
            calibrationCommentLabel.text = ""
            sender.setTitle("Next", for: .normal)
            print("\n\n----------------------------------------------------")
            print("キャリブレーション静止開始:\(frameNum)")
            print("----------------------------------------------------\n\n")
            
        case 2:
            calibrationCommentLabel.text = "鼻を+に合わせて\n距離を30cmくらいに調整してね↓\n出てくる矢印の方向にEye Glanceしてね"
            calibrationCenterLabel.text = "＋"
            sender.setTitle("Start", for: .normal)
            
        case 3, 7:
            calibrationCommentLabel.text = ""
            calibrationCenterLabel.text = "↖︎"
            sender.setTitle("Next", for: .normal)
            if pushTimes == 3 {
                print("\n\n----------------------------------------------------")
                print("キャリブレーション30開始:\(frameNum)")
                print("----------------------------------------------------\n\n")
            }
            
        case 4, 8:
            calibrationCenterLabel.text = "↗︎"
            
        case 5, 9:
            calibrationCenterLabel.text = "↙︎"
            
        case 6, 10:
            calibrationCenterLabel.text = "↘︎"
            
        case 11:
            calibrationCommentLabel.text = "これでバッチリ入力できます"
            calibrationCenterLabel.text = ""
            sender.setTitle("閉じる", for: .normal)
            print("\n\n----------------------------------------------------")
            print("キャリブレーション30終了:\(frameNum)")
            print("----------------------------------------------------\n\n")
            
        case 13:
            calibrationCommentLabel.text = ""
            sender.setTitle("Calibration", for: .normal)
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

