//
//  FrameProcessor.swift
//  IrisEyeGlance
//

import Foundation
import IrisEyeGlanceCore

/// Runs feature extraction, gesture detection, text composition, calibration and CSV
/// logging on a dedicated serial queue and reports one `Update` per frame on the main queue.
/// The view controller only renders updates and forwards user actions.
final class FrameProcessor: @unchecked Sendable {

    struct Update: Sendable {
        var cursorPoint: CGPoint
        var region: Int
        var regionRect: CGRect?
        var regionChanged: Bool
        var result: FrameResult
        var action: InputAction
        var layout: KeyboardLayout
        var calibrationStep: Calibrator.Step
        /// Set on the frame that completes a calibration.
        var calibrationResult: CalibrationResult?
        /// Camera frames captured so far (display only).
        var cameraFrames: Int
    }

    // Camera intrinsics of the front camera used during the original experiments.
    static let focalLength = 1304.924438
    static let imageWidth = 1080.0
    static let imageHeight = 1920.0

    private let queue = DispatchQueue(label: "jp.lab413.IrisEyeGlance.FrameProcessor", qos: .userInteractive)
    private let normalizer = LandmarkNormalizer()
    private var extractor: EyeFeatureExtractor
    private var pipeline: EyeInputPipeline
    private var composer = TextComposer()
    private var regionTracker = RegionChangeTracker()
    private var calibrator = Calibrator()
    private var recorder: CSVRecorder?
    private var frameIndex = 0
    private var panelFrame: InputPanelFrame?
    private var screenSize: CGSize

    /// Called on the main queue for every processed frame.
    var onUpdate: (@MainActor @Sendable (Update) -> Void)?

    init(parameters: DetectionParameters, screenSize: CGSize) {
        extractor = EyeFeatureExtractor(depthEstimator: DepthEstimator(focalLength: FrameProcessor.focalLength,
                                                                        imageWidth: FrameProcessor.imageWidth,
                                                                        imageHeight: FrameProcessor.imageHeight))
        pipeline = EyeInputPipeline(parameters: parameters)
        self.screenSize = screenSize
    }

    // MARK: Input

    /// Feed one frame of tracker landmarks (normalized coordinates). Safe from any thread.
    func process(landmarks: [CGPoint], cameraFrame: Int = 0) {
        queue.async { self.processOnQueue(landmarks, cameraFrame: cameraFrame) }
    }

    /// Panel geometry used to map the cursor to an input region. Pass nil to disable input.
    func setPanelFrame(_ frame: InputPanelFrame?) {
        queue.async { self.panelFrame = frame }
    }

    /// Size of the view the cursor is drawn in.
    func setScreenSize(_ size: CGSize) {
        queue.async { self.screenSize = size }
    }

    func setParameters(_ parameters: DetectionParameters) {
        queue.async { self.pipeline.parameters = parameters }
    }

    var parameters: DetectionParameters {
        queue.sync { pipeline.parameters }
    }

    var layout: KeyboardLayout {
        queue.sync { composer.layout }
    }

    /// Switches the panel layout (also resets the pending case toggle).
    func setLayout(_ layout: KeyboardLayout) {
        queue.async { self.composer.setLayout(layout) }
    }

    /// Clears all detector state, the frame counter and the pending text state.
    func reset() {
        queue.async {
            self.frameIndex = 0
            self.extractor.reset()
            self.pipeline.reset()
            self.regionTracker.reset()
            self.composer = TextComposer(layout: self.composer.layout)
        }
    }

    // MARK: Calibration

    /// Advances the calibration flow and returns the new step.
    func advanceCalibration() -> Calibrator.Step {
        queue.sync {
            calibrator.advance()
            return calibrator.step
        }
    }

    var calibrationStep: Calibrator.Step {
        queue.sync { calibrator.step }
    }

    // MARK: Recording

    func startRecording(to url: URL) throws {
        try queue.sync {
            recorder = try CSVRecorder(url: url)
        }
    }

    func stopRecording() {
        queue.sync {
            recorder?.close()
            recorder = nil
        }
    }

    // MARK: Processing

    private func processOnQueue(_ landmarks: [CGPoint], cameraFrame: Int) {
        guard landmarks.count >= FaceFrame.landmarkCount else { return }
        frameIndex += 1
        let frame = FaceFrame(index: frameIndex, landmarks: landmarks)

        // Cursor and region
        let nose = normalizer.normalize(frame[.noseTip])
        let cursor = CGPoint(x: nose.x * screenSize.width, y: nose.y * screenSize.height)
        var region = 0
        var regionRect: CGRect?
        if let panelFrame {
            let resolver = InputRegionResolver(panel: panelFrame)
            region = resolver.region(at: cursor)
            regionRect = resolver.rect(forRegion: region)
        }
        let regionChanged = regionTracker.update(region: region, frame: frameIndex)
        if regionChanged {
            pipeline.noteRegionChange(atFrame: frameIndex)
        }

        // Features and gestures
        let features = extractor.process(frame)
        let result = pipeline.process(features)
        var action: InputAction = .none
        if let event = result.event {
            action = composer.action(for: event, region: region)
        }

        // Calibration
        var calibrationResult: CalibrationResult?
        if calibrator.isActive {
            let wasDone = calibrator.step == .done
            let distance = EyeGlanceDetector.waveform(features.glanceSample, correctionBase: Calibrator.correctionBase).distance
            calibrator.record(glanceDistance: distance,
                              areaUp: pipeline.glanceDetector.areaUp,
                              areaDown: pipeline.glanceDetector.areaDown)
            if !wasDone, calibrator.step == .done, let result = calibrator.result {
                pipeline.parameters.glanceThreshold = result.glanceThreshold
                pipeline.parameters.glanceIntegralMultiplier = result.glanceIntegralMultiplier
                pipeline.parameters.save(to: .standard)
                calibrationResult = result
            }
        }

        // Logging
        if var recorder, calibrator.step.shouldLogFrames {
            let input: String
            if case .insert(let character) = action { input = character } else { input = "" }
            try? recorder.append(FrameResultCSV.row(for: result, inputCharacter: input, region: region))
            self.recorder = recorder
        }

        let update = Update(cursorPoint: cursor,
                            region: region,
                            regionRect: regionRect,
                            regionChanged: regionChanged,
                            result: result,
                            action: action,
                            layout: composer.layout,
                            calibrationStep: calibrator.step,
                            calibrationResult: calibrationResult,
                            cameraFrames: cameraFrame)
        guard let onUpdate else { return }
        DispatchQueue.main.async {
            onUpdate(update)
        }
    }
}
