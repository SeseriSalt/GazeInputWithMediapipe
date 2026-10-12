import Foundation
import Testing
@testable import IrisEyeGlanceCore

@Suite("Low-pass filter")
struct LowPassFilterTests {

    @Test("First sample passes through, later samples are smoothed")
    func smoothing() {
        var filter = LowPassFilter(cutoffFrequency: 4, sampleRate: 30)
        #expect(filter.filter(10) == 10)
        let second = filter.filter(20)
        #expect(second > 10 && second < 20)
    }

    @Test("reset() forgets the previous value")
    func reset() {
        var filter = LowPassFilter(cutoffFrequency: 4, sampleRate: 30)
        _ = filter.filter(10)
        filter.reset()
        #expect(filter.filter(50) == 50)
    }
}

@Suite("Depth estimator")
struct DepthEstimatorTests {
    let estimator = DepthEstimator(focalLength: 1304.924438, imageWidth: 1080, imageHeight: 1920)

    @Test("Iris diameter is the mean of the vertical and horizontal rim distances in pixels")
    func irisDiameter() {
        let iris = [
            CGPoint(x: 0.5, y: 0.5),
            CGPoint(x: 0.49, y: 0.5), CGPoint(x: 0.5, y: 0.49),
            CGPoint(x: 0.51, y: 0.5), CGPoint(x: 0.5, y: 0.51),
        ]
        let diameter = estimator.irisDiameter(iris)
        #expect(abs(diameter - 30) < 1e-6)
    }

    @Test("Depth in millimetres matches the pinhole model used by the original code")
    func depth() {
        let depth = estimator.depth(irisCenter: CGPoint(x: 0.5, y: 0.5), irisDiameter: 30)
        #expect(abs(depth - 11.8 * 1304.924438 / 30) < 1e-6)
    }

    @Test("Distance between two landmarks is measured in pixels")
    func landmarkDistance() {
        let distance = estimator.pixelDistance(CGPoint(x: 0, y: 0), CGPoint(x: 0.1, y: 0))
        #expect(abs(distance - 108) < 1e-6)
    }
}

@Suite("Iris signal")
struct IrisSignalTests {

    @Test("Two-frame differences of iris and reference point")
    func differences() {
        var signal = IrisSignal()
        signal.update(irisCenter: CGPoint(x: 0.1, y: 0.1), referencePoint: CGPoint(x: 0.5, y: 0.5))
        signal.update(irisCenter: CGPoint(x: 0.2, y: 0.1), referencePoint: CGPoint(x: 0.5, y: 0.5))
        signal.update(irisCenter: CGPoint(x: 0.3, y: 0.3), referencePoint: CGPoint(x: 0.6, y: 0.5))

        #expect(abs(signal.irisDelta2.x - 0.2) < 1e-9)
        #expect(abs(signal.irisDelta2.y - 0.2) < 1e-9)
        #expect(abs(signal.referenceDelta2.x - 0.1) < 1e-9)
        // iris movement with the head movement removed
        #expect(abs(signal.irisMinusReferenceDelta2.x - 0.1) < 1e-9)
        #expect(abs(signal.irisMinusReferenceDelta2.y - 0.2) < 1e-9)
    }
}

@Suite("Eye feature extractor")
struct EyeFeatureExtractorTests {

    private func frame(index: Int, leftEyelidGap: Double, rightEyelidGap: Double) -> FaceFrame {
        var landmarks = Array(repeating: CGPoint(x: 0.5, y: 0.5), count: FaceFrame.landmarkCount)
        landmarks[FaceMeshIndex.leftUpperEyelid.rawValue] = CGPoint(x: 0.4, y: 0.4)
        landmarks[FaceMeshIndex.leftLowerEyelid.rawValue] = CGPoint(x: 0.4, y: 0.4 + leftEyelidGap)
        landmarks[FaceMeshIndex.rightUpperEyelid.rawValue] = CGPoint(x: 0.6, y: 0.4)
        landmarks[FaceMeshIndex.rightLowerEyelid.rawValue] = CGPoint(x: 0.6, y: 0.4 + rightEyelidGap)
        for (offset, index) in FaceMeshIndex.leftIris.enumerated() {
            landmarks[index.rawValue] = [CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.39, y: 0.5), CGPoint(x: 0.4, y: 0.49), CGPoint(x: 0.41, y: 0.5), CGPoint(x: 0.4, y: 0.51)][offset]
        }
        for (offset, index) in FaceMeshIndex.rightIris.enumerated() {
            landmarks[index.rawValue] = [CGPoint(x: 0.6, y: 0.5), CGPoint(x: 0.59, y: 0.5), CGPoint(x: 0.6, y: 0.49), CGPoint(x: 0.61, y: 0.5), CGPoint(x: 0.6, y: 0.51)][offset]
        }
        return FaceFrame(index: index, landmarks: landmarks)
    }

    @Test("Eyelid heights are measured in pixels and differenced frame to frame")
    func eyelidHeights() {
        var extractor = EyeFeatureExtractor(depthEstimator: DepthEstimator(focalLength: 1304.924438, imageWidth: 1080, imageHeight: 1920))
        let first = extractor.process(frame(index: 1, leftEyelidGap: 0.01, rightEyelidGap: 0.01))
        #expect(abs(first.leftEyelidHeight - 19.2) < 1e-6)
        #expect(abs(first.rightEyelidHeight - 19.2) < 1e-6)

        let second = extractor.process(frame(index: 2, leftEyelidGap: 0.005, rightEyelidGap: 0.01))
        #expect(abs(second.leftEyelidDiff - (-9.6)) < 1e-6)
        #expect(abs(second.rightEyelidDiff) < 1e-6)
        #expect(abs(second.eyelidDiffLR - (-9.6)) < 1e-6)
    }

    @Test("Depth used for thresholds becomes available after the warm-up window")
    func depthWarmup() {
        var extractor = EyeFeatureExtractor(depthEstimator: DepthEstimator(focalLength: 1304.924438, imageWidth: 1080, imageHeight: 1920))
        var last = extractor.process(frame(index: 1, leftEyelidGap: 0.01, rightEyelidGap: 0.01))
        #expect(last.thresholdDepth == 0)
        for index in 2...6 {
            last = extractor.process(frame(index: index, leftEyelidGap: 0.01, rightEyelidGap: 0.01))
        }
        #expect(last.thresholdDepth > 0)
        #expect(abs(last.thresholdDepth - last.depth) < 1e-6)
    }
}
