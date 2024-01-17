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
    @IBOutlet weak var inputDesignImage: UIImageView!
    @IBOutlet weak var consonantDesignImage: UIImageView!
    
    @IBOutlet weak var ISCenterLabel: UILabel!
    @IBOutlet weak var ISWidthLabel: UILabel!
    
    @IBOutlet weak var questionLabel: UILabel!
    
    @IBOutlet weak var movementLabel: UILabel!
    
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var createCSVButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    
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
    var leftEyelidHeightPrev: Float = 0.0
    var rightEyelidHeightPrev: Float = 0.0
    var lrHeightDiff: Float = 0.0
    var lrDiff: Float = 0.0
    var lrDiffPrev: Float = 0.0
    
    // wink・brinkの閾値
    //    public let ikichiWink: Float = 0.6
    var winkIkichiMax: Float = 0.0
    var winkIkichiMin: Float = 0.0
    var winkIkichiHeight: Float = 0.0
    var brinkIkichi: Float = 0.0
    
    var winkIkichiMaxNext: Float = 0.0
    var winkIkichiMinNext: Float = 0.0
    var heightIkichiNext: Float = 0.0
    var brinkIkichNext: Float = 0.0
    
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
    var heightAvg5: Float = 0
    var heightAll: [Float] = []
    var areaChangeFrame = 0
    
    //Eye Glance用
    var normalizedLeftIris: [CGPoint] = [CGPoint(x: 0.0, y: 0.0)]
    var normalizedRightIris: [CGPoint] = [CGPoint(x: 0.0, y: 0.0)]
    
    var leftIrisPrev =  CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    var rightIrisPrev = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    var leftIrisPrev2 = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    var rightIrisPrev2 = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    var refPointPrev2 = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    var refPointArr: [CGFloat] = []
    var refPointMoveAvePrev: CGFloat = 0.0
    var filteredRefPointPrev =  CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    
    var glanceFlag: Int = 0
    var glanceFirstPoint: Int = 0
    var distGlanceNum: Int = 0
    
    var firstDirect: CGFloat = 0.0
    var firstDirectIris = lrPoint(l: CGFloat(0.0), r: CGFloat(0.0))
    var firstAreaUp: CGFloat = 0.0
    var secondAreaUp: CGFloat = 0.0
    var countAreaUp: CGFloat = 0.0
    var secondDirect: CGFloat = 0.0
    var secondDirectIris = lrPoint(l: CGFloat(0.0), r: CGFloat(0.0))
    var firstAreaDown: CGFloat = 0.0
    var secondAreaDown: CGFloat = 0.0
    var countAreaDown: CGFloat = 0.0
    var directUp: CGFloat = 0.0
    var directIrisUp = lrPoint(l: CGFloat(0.0), r: CGFloat(0.0))
    var directDown: CGFloat = 0.0
    var directIrisDown = lrPoint(l: CGFloat(0.0), r: CGFloat(0.0))
    var areaDown: CGFloat = 0.0
    var areaUp: CGFloat = 0.0
    var inputResult: Int = 0
    var endFrame: Int = 0
    var arrayAreaDown: [(frame: Int, area: CGFloat, prev: CGFloat, peak: CGFloat, next: CGFloat, direct_d: CGFloat, direct_i: lrPoint, isUsed: Bool)] = [(frame: 0, area: 0, prev: 0, peak: 0, next: 0, direct_d: 0, direct_i: lrPoint(l: 0.0, r: 0.0), isUsed: false)]
    var arrayAreaUp: [(frame: Int, area: CGFloat, prev: CGFloat, peak: CGFloat, next: CGFloat, direct_d: CGFloat, direct_i: lrPoint, isUsed: Bool)] = [(frame: 0, area: 0, prev: 0, peak: 0, next: 0, direct_d: 0, direct_i: lrPoint(l: 0.0, r: 0.0), isUsed: false)]
    var glanceDistPrev: CGFloat = 0.0
    var glanceUpPrev: CGFloat = 0.0
    var glanceDownPrev: CGFloat = 0.0
    var glanceUpPeak: CGFloat = 0.0
    var glanceDownPeak: CGFloat = 0.0
    var glanceUpNext: CGFloat = 100.0
    var glanceDownNext: CGFloat = -100.0
    

    
    
    var relativeDistance_x = lrPoint(l: 0.0, r: 0.0)
    var relativeDistance_xPrev = lrPoint(l: 0.0, r: 0.0)
    var refPointPrev = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
    
    var leftInnerWhitePrev: CGFloat = 0.0
    var leftOuterWhitePrev: CGFloat = 0.0
    var rightInnerWhitePrev: CGFloat = 0.0
    var rightOuterWhitePrev: CGFloat = 0.0
    
    var glanceIkichiMaxBig: CGFloat = 0.0
    var glanceIkichiMinBig: CGFloat = 0.0
    var ikichiAreaUpBig: CGFloat = 0.0
    var ikichiAreaDownBig: CGFloat = 0.0
    var glanceIkichiMaxSmall: CGFloat = 0.0
    var glanceIkichiMinSmall: CGFloat = 0.0
    var ikichiAreaUpSmall: CGFloat = 0.0
    var ikichiAreaDownSmall: CGFloat = 0.0
    var arraynormalizedLeftIris: [[CGPoint]] = [[CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.0, y: 0.0)], [CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.0, y: 0.0)]]
    var arraynormalizedRightIris: [[CGPoint]] = [[CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.0, y: 0.0)], [CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0.0, y: 0.0)]]
    var arrayfilteredRefPoint: [CGPoint] = []
    
    
    // カーソル移動の検知用
    var nosePointPrev = CGPoint(x: 0.0, y: 0.0)
    var leftCheekPrev = CGPoint(x: 0.0, y: 0.0)
    var rightCheekPrev = CGPoint(x: 0.0, y: 0.0)
    var faceMoveFlag: Int = 0
    var faceMoveFirstNum: Int = 0
    var faceMoveEndNum: Int = 0
    var faceMoveIkichi: CGFloat = 0.0
    
    //短すぎて初期化した時のフレーム（wink, glance）
    var distWinkInitNum: Int = 0
    var distGlanceInitNum: Int = 0
    
    //カットオフに関する処理
    
    let sampleRate = 30.0 // 30 fps
    let cutoffFrequency = 4.0 // 5 Hz
    // フィルタのインスタンス
    lazy var lowPassFilterX = LowPassFilter(cutoffFrequency: cutoffFrequency, sampleRate: sampleRate)
    lazy var lowPassFilterY = LowPassFilter(cutoffFrequency: cutoffFrequency, sampleRate: sampleRate)
    
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
            
  // 顔の移動量検知                          いらない！！！！
            // 鼻(カーソル)の変化量
            let nosePointDIff_x = nosePoint.x - nosePointPrev.x
            let nosePointDIff_y = nosePoint.y - nosePointPrev.y
            let nosePointMove = sqrt(pow(nosePointDIff_x, 2) + pow(nosePointDIff_y, 2))
            
            // 左頬1点の変化量
            let normalizedleftCheek = normalizedLandmarkPoint(point: landmarkAll[50])
            let leftCheek = CGPoint(x: normalizedleftCheek.x * screenWidth, y: normalizedleftCheek.y * screenHeight)
            
            let leftCheekDIff_x = leftCheek.x - leftCheekPrev.x
            let leftCheekDIff_y = leftCheek.y - leftCheekPrev.y
            let leftCheekMove = sqrt(pow(leftCheekDIff_x, 2) + pow(leftCheekDIff_y, 2))
            
            // 右頬1点の変化量
            let normalizedRightCheek = normalizedLandmarkPoint(point: landmarkAll[280])
            let rightCheek = CGPoint(x: normalizedRightCheek.x * screenWidth, y: normalizedRightCheek.y * screenHeight)
            
            let rightCheekDIff_x = rightCheek.x - rightCheekPrev.x
            let rightCheekDIff_y = rightCheek.y - rightCheekPrev.y
            let rightCheekMove = sqrt(pow(rightCheekDIff_x, 2) + pow(rightCheekDIff_y, 2))
            
//            let faceMove = nosePointMove * leftCheekMove * rightCheekMove
            
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
            let normalizedLeftIris: [CGPoint] = normalizeLandmarks(leftEyeLandmark)
            let normalizedRightIris: [CGPoint] = normalizeLandmarks(rightEyeLandmark)
            arraynormalizedLeftIris.insert(normalizedLeftIris, at: 0)
            arraynormalizedRightIris.insert(normalizedRightIris, at: 0)




            //  y方向
//          normalizedLeftIris[0]は虹彩中心
            let leftIrisDiff_y = normalizedLeftIris[0].y - leftIrisPrev.y
            let rightIrisDiff_y = normalizedRightIris[0].y - rightIrisPrev.y
            var leftIris2Diff_y:CGFloat = 0
            var rightIris2Diff_y:CGFloat = 0
            //25以上じゃないと安定しないため
            if frameNum > 25{
                leftIris2Diff_y = normalizedLeftIris[0].y - arraynormalizedLeftIris[2][0].y
                rightIris2Diff_y = normalizedRightIris[0].y - arraynormalizedRightIris[2][0].y
                //arraynoramalizedLeftIris[2][0]は2フレーム前の虹彩中心の座標(x, y)
            }
            // x方向
//          normalizedLeftIris[0]は虹彩中心
            let leftIrisDiff_x = normalizedLeftIris[0].x - leftIrisPrev.x
            let rightIrisDiff_x = normalizedRightIris[0].x - rightIrisPrev.x
            var leftIris2Diff_x:CGFloat = 0
            var rightIris2Diff_x:CGFloat = 0
            if frameNum > 25{
                leftIris2Diff_x = normalizedLeftIris[0].x - arraynormalizedLeftIris[2][0].x
                rightIris2Diff_x = normalizedRightIris[0].x - arraynormalizedRightIris[2][0].x
            }

            
            // 基準点
            let refPoint = CGPoint(x: CGFloat((landmarkAll[45][0] + landmarkAll[1][0] + landmarkAll[275][0]) / 3), y: CGFloat((landmarkAll[5][1] + landmarkAll[4][1] + landmarkAll[1][1]) / 3))
            let refPointDiff = sqrt(pow(refPoint.x - refPointPrev2.x, 2) + pow(refPoint.y - refPointPrev2.y, 2))
            
            
            //基準点をローパスフィルタにかける
            let filteredRefPointX = lowPassFilterX.filter(value: refPoint.x)
            let filteredRefPointY = lowPassFilterY.filter(value: refPoint.y)
            let filteredRefPoint = CGPoint(x: filteredRefPointX, y: filteredRefPointY)
            arrayfilteredRefPoint.insert(filteredRefPoint, at: 0)
            
            
            //filteredRefPointの差分値
            let filteredRefPointDiff_x = filteredRefPoint.x - filteredRefPointPrev.x
            let filteredRefPointDiff_y = filteredRefPoint.y - filteredRefPointPrev.y
            let filteredRefPointDiff = CGPoint(x: filteredRefPointDiff_x, y: filteredRefPointDiff_y)
            var filteredRefPoint2Diff_x: CGFloat = 0
            var filteredRefPoint2Diff_y: CGFloat = 0
            
            if frameNum > 25{
                filteredRefPoint2Diff_x = filteredRefPointX - arrayfilteredRefPoint[2].x
                filteredRefPoint2Diff_y = filteredRefPointY - arrayfilteredRefPoint[2].y
            }
            
            //目ーローパス鼻の差分波形
            let leftEyeNoseDiff = CGPoint(x: leftIrisDiff_x - filteredRefPointDiff_x, y: leftIrisDiff_y - filteredRefPointDiff_y)
            let rightEyeNoseDiff = CGPoint(x: rightIrisDiff_x - filteredRefPointDiff_x, y: rightIrisDiff_y - filteredRefPointDiff_y)
            var leftEyeNose2Diff = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
            var rightEyeNose2Diff = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
            //25以上じゃないと安定しないため
            if frameNum > 25{
                leftEyeNose2Diff = CGPoint(x: leftIris2Diff_x - filteredRefPoint2Diff_x, y: leftIris2Diff_y - filteredRefPoint2Diff_y)
                rightEyeNose2Diff = CGPoint(x: rightIris2Diff_x - filteredRefPoint2Diff_x, y: rightIris2Diff_y - filteredRefPoint2Diff_y)
            }

            
         // いらない！！！！！
            refPointArr.insert(refPointDiff, at: 0)
            var refPointMoveSum :CGFloat = 0.0
            let moveAveNum: Int = 3
            if (refPointArr.count > moveAveNum) {
                for i in (0 ..< moveAveNum) {
                    refPointMoveSum += refPointArr[i]
                }
            }
            let refPointMoveAve = refPointMoveSum / CGFloat(moveAveNum)
            let refPointMoveAveDiff = refPointMoveAve - refPointMoveAvePrev
            
            let faceMove = refPointMoveAveDiff * 800
            
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
            
  // 判別
            // 閾値の決定
            let ikichi = ikichiDecision(depth: defDepth)
            
            
            // brink判別
            let brink = brinkDitect()
            
            // wink判別
            let wink = winkDitect()
            
            // Eye Glance判別     refPointだけちょっと心配
            let eyeWave = eyeGlance(left: CGPoint(x: leftEyeNose2Diff.x, y: leftEyeNose2Diff.y), right: CGPoint(x: rightEyeNose2Diff.x, y: rightEyeNose2Diff.y), refDiff: CGPoint(x: refPointDiff, y: refPointDiff), ikichi: (maxBig: glanceIkichiMaxBig, minBig: glanceIkichiMinBig, maxSmall: glanceIkichiMaxSmall, minSmall: glanceIkichiMinSmall, areaupBig: ikichi.areaUpBig, areadownBig: ikichi.areaDownBig, areaupSmall: ikichi.areaUpSmall, areadownSmall: ikichi.areaDownSmall))
            
            
            // 実験用入力判別
            judgment()
            
            // 入力が起こったフレームの出力用
            let printWinkFrame = distWinkNum == frameNum ? String(distWinkNum) : ""
            let printBrinkFrame = distBrinkNum == frameNum ? String(distBrinkNum) : ""
            let printGlanceFrame = distGlanceNum == frameNum ? String(distGlanceNum) : ""
            let printWinkInitFrame = frameNum - distWinkInitNum <= 4 ? String(distWinkInitNum) : ""
            let printGlanceInitFrame = frameNum - distGlanceInitNum <= 4 ? String(distGlanceInitNum) : ""
            let printFaceMoveFrame = frameNum - faceMoveEndNum <= 5 ? String(faceMoveEndNum) : ""
            
            let aadFrame: Any = arrayAreaDown.count == 0 ? "" : arrayAreaDown[0].frame
            let aadArea: Any  = arrayAreaDown.count == 0 ? "" : arrayAreaDown[0].area
            let aauFrame: Any  = arrayAreaUp.count == 0 ? "" : arrayAreaUp[0].frame
            let aauArea: Any  = arrayAreaUp.count == 0 ? "" : arrayAreaUp[0].area
            
//実験データ出力
            func printVariablesAsCSV(_ variables: Any...) {
                let values = variables.map { "\($0)" }.joined(separator: ", ")
                print(values)
                if recFlag == 1 {
                    // CSVファイルにデータを追記
                    appendDataToCSVFile(data: values + "\n")
                }
            }
            
            let HEADER = "frameNum, defDepth, inputCharacter, eyeWave.glanceDist, eyeWave.correctionValue, areaChangeFlag * 10, ikichi.glanceMaxSmall, ikichi.glanceMinSmall, areaChangeFrame, areaDown, ikichi.areaDownBig, ikichi.areaDownSmall, aadFrame, aadArea, arrayAreaDown.count, glanceDownNext, glanceFlag, areaUp, ikichi.areaUpBig, ikichi.areaUpSmall, aauFrame, aauArea, arrayAreaUp.count, glanceUpNext, directDown, directUp"
            //            if frameNum == 101 {
            //                print("\n\n---------------------------------------------------------------------------------------------")
            //                print(HEADER)
            //            }
            // データの出力　引数そのままコピペしたらヘッダになる
            
            printVariablesAsCSV(frameNum, defDepth, inputCharacter, eyeWave.glanceDist, eyeWave.correctionValue, areaChangeFlag * 10, ikichi.glanceMaxSmall, ikichi.glanceMinSmall, areaChangeFrame, areaDown, ikichi.areaDownBig, ikichi.areaDownSmall, aadFrame, aadArea, arrayAreaDown.count, glanceDownNext, glanceFlag, areaUp, ikichi.areaUpBig, ikichi.areaUpSmall, aauFrame, aauArea, arrayAreaUp.count, glanceUpNext, directDown, directUp)
            
            
  // ↓ここから下：次のフレームで使用する現在の値を保存・初期化する処理
            leftEyelidHeightPrev = leftEyelidHeight
            rightEyelidHeightPrev = rightEyelidHeight
            
            lrDiffPrev = lrDiff
            leftDepthPrev = leftDepth_mm
            rightDepthPrev = rightDepth_mm
            
            leftIrisPrev = normalizedLeftIris[0]
            rightIrisPrev = normalizedRightIris[0]
            
            filteredRefPointPrev = filteredRefPoint
            
            refPointPrev2 = refPoint
            refPointMoveAvePrev = refPointMoveAve
            
            nosePointPrev = nosePoint
            leftCheekPrev = leftCheek
            rightCheekPrev = rightCheek
            
            
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
            
//            faceMoveIkichi = ikichi.faceMove
            
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
        faceMoveFlag = 0
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
    
    // 設定画面から戻る時の処理
    func restartCapture() {
        camera.start()
        
        frameNum = 0
        distBrinkNum = 0
        distWinkNum = 0
        distGlanceInitNum = 0
        distWinkInitNum = 0
        distGlanceNum = 0
        faceMoveFlag = 0
        allInit()
    }
    
    func irisTracker(_ irisTracker: SYIris!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        // キャプチャにランドマークを描画
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
        }
    }
}
