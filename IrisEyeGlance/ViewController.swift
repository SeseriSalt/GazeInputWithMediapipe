//
//  ViewController.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2022/10/12.
//

import UIKit
import AVFoundation
import IrisEyeGlanceCore

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
    lazy var processor = FrameProcessor(parameters: DetectionParameters(userDefaults: .standard),
                                        screenSize: UIScreen.main.bounds.size)

    /// Camera frames received so far (display only).
    var frameNum = 0
    /// Frame index of the last recognized gesture, used to clear the feedback label.
    private var lastEventFrame = 0
    private static let feedbackFrames = 4

    var experiment = ExperimentSession()
    var isRecording = false

    // Panel geometry
    var circleLayer: CAShapeLayer?
    var rectLayer: CAShapeLayer?
    var tapCount = 0
    let imageSizeList = [(175, 147), (200, 168), (150, 126)]
    let imageSizeListCon = [(87, 73), (127, 106), (75, 63)]
    let IMAGE_INITISL_POSITION = CGPoint(x: 195.0, y: 422.0)
    let lineWidthList = [1.5, 1.5, 1.25]

    private let feedbackGenerator = UISelectionFeedbackGenerator()

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

        createCSVButton.setImage(UIImage(systemName: "record.circle"), for: .normal)

        inputDesignImage.center = IMAGE_INITISL_POSITION
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        inputDesignImage.addGestureRecognizer(panGesture)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        inputDesignImage.addGestureRecognizer(doubleTapGesture)
        inputDesignImage.isUserInteractionEnabled = true

        updateImageViewSize()

        inputLabel.layer.borderWidth = 0.5
        inputLabel.text = ""
        questionLabel.layer.borderWidth = 0.5
        questionLabel.text = experiment.currentQuestion
        resultLabel.text = ""
        feedbackGenerator.prepare()

        processor.onUpdate = { [weak self] update in
            self?.apply(update)
        }
        processor.setPanelFrame(currentPanelFrame())
    }

    // MARK: Camera / tracker callbacks

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        tracker.processVideoFrame(pixelBuffer)

        frameNum += 1
        let image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
        let count = frameNum
        DispatchQueue.main.async {
            self.imageview.image = image
            self.frameLabel.text = "\(count)"
        }
    }

    func irisTracker(_ irisTracker: SYIris!, didOutputLandmarks landmarks: [Landmark]!) {
        guard let landmarks else { return }
        let points = landmarks.map { CGPoint(x: Double($0.x), y: Double($0.y)) }
        processor.process(landmarks: points)
    }

    func irisTracker(_ irisTracker: SYIris!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        // The tracker's annotated frame is not displayed.
    }

    // MARK: Rendering one frame

    @MainActor
    private func apply(_ update: FrameProcessor.Update) {
        drawCursor(point: update.cursorPoint)
        if update.regionChanged {
            feedbackGenerator.selectionChanged()
        }
        showRegion(update.region, rect: update.regionRect, layout: update.layout)

        let features = update.result.features
        leftLavel.text = "\(Int((features.leftDepth / 10).rounded()))"
        rightLabel.text = "\(Int((features.rightDepth / 10).rounded()))"

        if let event = update.result.event {
            lastEventFrame = features.frame
            movementLabel.text = String(event.legacyCode)
            switch event {
            case .blink:
                lateFlagLabel.text = "blink"
                lateFlagLabel.textColor = .green
            case .wink(let eye):
                let color: UIColor = eye == .left ? .red : .blue
                inputLabel.textColor = color
                questionLabel.textColor = color
            case .glance:
                break
            }
        } else if features.frame - lastEventFrame > ViewController.feedbackFrames {
            movementLabel.text = "___"
        }

        handle(update.action)

        if let result = update.calibrationResult {
            print("Calibration finished: glance threshold \(result.glanceThreshold), integral multiplier \(result.glanceIntegralMultiplier)")
            showCalibrationStep(update.calibrationStep)
        }
    }

    @MainActor
    private func handle(_ action: InputAction) {
        switch action {
        case .none:
            break
        case .insert(let character):
            inputLabel.text = character
            experiment.recordAttempt()
            if let outcome = experiment.check(character) {
                showExperimentOutcome(outcome)
            }
        case .switchLayout(let layout):
            inputDesignImage.image = UIImage(named: layout.isAlphabet ? "designAlpha" : "designJapanese")
        case .toggleCase(let upper):
            inputLabel.text = upper ? inputLabel.text?.uppercased() : inputLabel.text?.lowercased()
        }
    }

    // MARK: Buttons

    @IBAction func resetButtonPush(_ sender: UIButton) {
        resetExperiment()
        frameNum = 0
        lastEventFrame = 0
        processor.reset()
    }

    @IBAction func createCSVButtonPush(_ sender: UIButton) {
        if isRecording {
            processor.stopRecording()
            sender.setTitle("Data Acquisition", for: .normal)
            sender.setTitleColor(.blue, for: .normal)
            sender.setImage(UIImage(systemName: "record.circle"), for: .normal)
            sender.tintColor = .blue
            isRecording = false
        } else {
            let url = getDocumentsDirectory().appendingPathComponent("\(getCurrentTime()).csv", isDirectory: false)
            do {
                try processor.startRecording(to: url)
            } catch {
                print("Could not start recording: \(error)")
                return
            }
            sender.setTitle("Stop", for: .normal)
            sender.setTitleColor(.red, for: .normal)
            sender.setImage(UIImage(systemName: "stop.circle"), for: .normal)
            sender.tintColor = .red
            isRecording = true
        }
    }

    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }

    /// Settings screen is about to be presented: stop the capture.
    @IBAction func settingButtonPush(_ sender: Any) {
        camera.stop()
    }

    @IBAction func calibrationButtonPush(_ sender: UIButton) {
        let step = processor.advanceCalibration()
        showCalibrationStep(step)
    }

    /// Called by the settings screen when it closes.
    func restartCapture(with parameters: DetectionParameters) {
        processor.setParameters(parameters)
        camera.start()
        frameNum = 0
        lastEventFrame = 0
        processor.reset()
    }
}
