//
//  TrackerBridge.swift
//  IrisEyeGlance
//
//  Receives camera frames, runs the SYIris (MediaPipe) tracker and forwards the
//  landmarks to the frame processor. Lives off the main actor so the delegate
//  callbacks never touch UI state.
//

import AVFoundation
import Foundation
import IrisEyeGlanceCore

final class TrackerBridge: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, SYIrisDelegate, @unchecked Sendable {
    private let tracker: SYIris
    private let processor: FrameProcessor
    private let lock = NSLock()
    private var cameraFrames = 0

    init?(processor: FrameProcessor) {
        guard let tracker = SYIris() else { return nil }
        self.tracker = tracker
        self.processor = processor
        super.init()
        tracker.delegate = self
        tracker.startGraph()
    }

    func resetFrameCount() {
        lock.withLock { cameraFrames = 0 }
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lock.withLock { cameraFrames += 1 }
        tracker.processVideoFrame(pixelBuffer)
    }

    // MARK: SYIrisDelegate

    func irisTracker(_ irisTracker: SYIris!, didOutputLandmarks landmarks: [Landmark]!) {
        guard let landmarks else { return }
        let points = landmarks.map { CGPoint(x: Double($0.x), y: Double($0.y)) }
        let frames = lock.withLock { cameraFrames }
        processor.process(landmarks: points, cameraFrame: frames)
    }

    func irisTracker(_ irisTracker: SYIris!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        // The tracker's annotated frame is not displayed; the live preview layer is used instead.
    }
}
