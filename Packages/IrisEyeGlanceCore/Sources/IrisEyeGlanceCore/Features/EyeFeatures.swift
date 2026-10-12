import CoreGraphics
import Foundation

/// Per-frame scalar features derived from the face mesh. This is the input to the detectors.
public struct EyeFeatures: Sendable {
    public var frame: Int = 0

    // Eyelid opening in pixels and its frame-to-frame change.
    public var leftEyelidHeight: Double = 0
    public var rightEyelidHeight: Double = 0
    public var leftEyelidDiff: Double = 0
    public var rightEyelidDiff: Double = 0
    /// `leftEyelidDiff - rightEyelidDiff`, the wink waveform.
    public var eyelidDiffLR: Double = 0
    public var previousEyelidDiffLR: Double = 0
    /// `leftEyelidHeight - rightEyelidHeight`.
    public var eyelidHeightDiffLR: Double = 0

    // Distance from the camera in millimetres.
    public var leftDepth: Double = 0
    public var rightDepth: Double = 0
    public var depth: Double = 0
    /// Depth used for threshold computation. Stays 0 during the warm-up window.
    public var thresholdDepth: Double = 0

    // Iris motion (normalized coordinates) over two frames.
    public var leftIrisDelta2: CGPoint = .zero
    public var rightIrisDelta2: CGPoint = .zero
    public var referenceDelta2: CGPoint = .zero
    public var leftIrisMinusReferenceDelta2: CGPoint = .zero
    public var rightIrisMinusReferenceDelta2: CGPoint = .zero

    // Head reference point, raw and low-pass filtered.
    public var referencePoint: CGPoint = .zero
    public var filteredReferencePoint: CGPoint = .zero
    public var filteredReferenceDeltaY: Double = 0
    public var rawReferenceDeltaY: Double = 0

    public init() {}

    /// Sample used by the glance detector.
    public var glanceSample: GlanceSample {
        GlanceSample(leftIrisDelta: leftIrisMinusReferenceDelta2,
                     rightIrisDelta: rightIrisMinusReferenceDelta2,
                     referenceDeltaY: referenceDelta2.y)
    }
}
