//
//  CalibrationViewController.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2024/01/16.
//

import UIKit
import AVFoundation

// mediapipeは現状dismissで遷移元に戻れないみたいなので一旦放置
class CalibrationViewController: UIViewController , AVCaptureVideoDataOutputSampleBufferDelegate, SYIrisDelegate{
    
    @IBOutlet weak var Imageview: UIImageView!
    @IBOutlet weak var frameLabel: UILabel!
    @IBOutlet weak var leftLabel: UILabel!
    
    @IBOutlet weak var rightLabel: UILabel!
    
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var commentLabel: UILabel!
    
    let camera = Camera()
    let tracker: SYIris = SYIris()!
    
    public let FOCAL_LENGTH: Float = 1304.924438
    public let WIDTH: Float = 1080.0
    public let HEIGHT: Float = 1920.0
    public var frameNum: Int = 0
    
    //Eye Glance用
    lazy var leftEye = EyeData()
    lazy var rightEye = EyeData()
    
    //カットオフに関するパラメータ
    let SAMPLE_RATE = 30.0 // 30fps
    let CUTOFF_FREQUENCY = 4.0 // 4Hz
    // フィルタのインスタンス
    lazy var lowPassFilterX = LowPassFilter(cutoffFrequency: CUTOFF_FREQUENCY, sampleRate: SAMPLE_RATE)
    lazy var lowPassFilterY = LowPassFilter(cutoffFrequency: CUTOFF_FREQUENCY, sampleRate: SAMPLE_RATE)
    
    let screenWidth = UIScreen.main.bounds.width // (390.0)
    let screenHeight = UIScreen.main.bounds.height // (844.0)
    
    var pushTimes: Int = 0
    
    var dataArray20: [[CGFloat]] = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
    var dataArray30: [[CGFloat]] = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
    var dataArray40: [[CGFloat]] = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.setSampleBufferDelegate(self)
        camera.start()
        tracker.startGraph()
        tracker.delegate = self
        
        Imageview.translatesAutoresizingMaskIntoConstraints = false
        Imageview.contentMode = .scaleAspectFill
        
        NSLayoutConstraint.activate([
            Imageview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            Imageview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            Imageview.topAnchor.constraint(equalTo: view.topAnchor),
            Imageview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        tracker.processVideoFrame(pixelBuffer)
        
        frameNum += 1
        DispatchQueue.main.async {
            self.Imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer!))
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
            self.leftLabel.text = "\(Int(round(leftDepth_mm / 10)))"
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
        
        
        
        
    }
    
    @IBAction func centerButtonAction(_ sender: UIButton) {
        switch pushTimes {
        case 0, 5, 10:
            commentLabel.text = ""
            sender.setTitle("↖︎", for: .normal)
            
        case 1, 6, 11:
            sender.setTitle("↗︎", for: .normal)
            
        case 2, 7, 12:
            sender.setTitle("↙︎", for: .normal)
            
        case 3, 8, 13:
            sender.setTitle("↘︎", for: .normal)
            
        case 4:
            commentLabel.text = "鼻を+に合わせて\n距離を30cmくらいに調整してね↓"
            sender.setTitle("スタート", for: .normal)
            
        case 9:
            commentLabel.text = "鼻を+に合わせて\n距離を40cmくらいに調整してね↓"
            sender.setTitle("スタート", for: .normal)
            
        case 14:
            commentLabel.text = "これでバッチリ入力できます"
            sender.setTitle("閉じる", for: .normal)
            
        case 15:
            camera.stop()
            
            let cameraVC = presentingViewController as? ViewController
            cameraVC?.restartCapture()
            
            dismiss(animated: true)
            
        default: break
            
        }
        
        
        
        pushTimes += 1
    }
    
    
    func irisTracker(_ irisTracker: SYIris!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
