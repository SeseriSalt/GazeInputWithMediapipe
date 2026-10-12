import CoreGraphics
import Foundation

/// Turns raw face frames into `EyeFeatures`. Holds the small amount of history
/// (previous eyelid heights, iris positions, filters) needed for differencing.
public struct EyeFeatureExtractor: Sendable {
    public static let sampleRate: Double = 30
    public static let cutoffFrequency: Double = 4
    /// Number of frames before the depth estimate is trusted for thresholds.
    public static let depthWarmupFrames = 5

    public var depthEstimator: DepthEstimator
    public var normalizer: LandmarkNormalizer

    private var lowPassX = LowPassFilter(cutoffFrequency: cutoffFrequency, sampleRate: sampleRate)
    private var lowPassY = LowPassFilter(cutoffFrequency: cutoffFrequency, sampleRate: sampleRate)
    private var leftSignal = IrisSignal()
    private var rightSignal = IrisSignal()

    private var previousLeftEyelidHeight = 0.0
    private var previousRightEyelidHeight = 0.0
    private var previousEyelidDiffLR = 0.0
    private var previousReferencePoint = CGPoint.zero
    private var previousFilteredReferencePoint = CGPoint.zero
    private var depthSampleCount = 0

    public init(depthEstimator: DepthEstimator, normalizer: LandmarkNormalizer = LandmarkNormalizer()) {
        self.depthEstimator = depthEstimator
        self.normalizer = normalizer
    }

    public mutating func process(_ frame: FaceFrame) -> EyeFeatures {
        var features = EyeFeatures()
        features.frame = frame.index

        // Eyelids
        features.leftEyelidHeight = depthEstimator.pixelDistance(frame[.leftUpperEyelid], frame[.leftLowerEyelid])
        features.rightEyelidHeight = depthEstimator.pixelDistance(frame[.rightUpperEyelid], frame[.rightLowerEyelid])
        features.leftEyelidDiff = features.leftEyelidHeight - previousLeftEyelidHeight
        features.rightEyelidDiff = features.rightEyelidHeight - previousRightEyelidHeight
        features.eyelidDiffLR = features.leftEyelidDiff - features.rightEyelidDiff
        features.previousEyelidDiffLR = previousEyelidDiffLR
        features.eyelidHeightDiffLR = features.leftEyelidHeight - features.rightEyelidHeight

        // Depth
        let leftIris = frame.points(FaceMeshIndex.leftIris)
        let rightIris = frame.points(FaceMeshIndex.rightIris)
        features.leftDepth = depthEstimator.depth(irisCenter: leftIris[0], irisDiameter: depthEstimator.irisDiameter(leftIris))
        features.rightDepth = depthEstimator.depth(irisCenter: rightIris[0], irisDiameter: depthEstimator.irisDiameter(rightIris))
        features.depth = (features.leftDepth + features.rightDepth) / 2
        depthSampleCount += 1
        features.thresholdDepth = depthSampleCount > EyeFeatureExtractor.depthWarmupFrames ? features.depth : 0

        // Head reference point (raw) and its low-pass filtered version
        let referenceX = FaceMeshIndex.referenceX.map { frame[$0].x }.reduce(0, +) / Double(FaceMeshIndex.referenceX.count)
        let referenceY = FaceMeshIndex.referenceY.map { frame[$0].y }.reduce(0, +) / Double(FaceMeshIndex.referenceY.count)
        let reference = CGPoint(x: referenceX, y: referenceY)
        let filtered = CGPoint(x: lowPassX.filter(reference.x), y: lowPassY.filter(reference.y))
        features.referencePoint = reference
        features.filteredReferencePoint = filtered
        features.rawReferenceDeltaY = reference.y - previousReferencePoint.y
        features.filteredReferenceDeltaY = filtered.y - previousFilteredReferencePoint.y

        // Iris motion relative to the filtered reference point
        leftSignal.update(irisCenter: normalizer.normalize(leftIris[0]), referencePoint: filtered)
        rightSignal.update(irisCenter: normalizer.normalize(rightIris[0]), referencePoint: filtered)
        features.leftIrisDelta2 = leftSignal.irisDelta2
        features.rightIrisDelta2 = rightSignal.irisDelta2
        features.referenceDelta2 = leftSignal.referenceDelta2
        features.leftIrisMinusReferenceDelta2 = leftSignal.irisMinusReferenceDelta2
        features.rightIrisMinusReferenceDelta2 = rightSignal.irisMinusReferenceDelta2

        // Remember state for the next frame
        previousLeftEyelidHeight = features.leftEyelidHeight
        previousRightEyelidHeight = features.rightEyelidHeight
        previousEyelidDiffLR = features.eyelidDiffLR
        previousReferencePoint = reference
        previousFilteredReferencePoint = filtered

        return features
    }

    public mutating func reset() {
        self = EyeFeatureExtractor(depthEstimator: depthEstimator, normalizer: normalizer)
    }
}
