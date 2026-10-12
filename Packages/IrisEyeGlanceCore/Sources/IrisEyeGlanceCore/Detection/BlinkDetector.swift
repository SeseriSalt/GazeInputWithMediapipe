import Foundation

/// Detects a blink: both eyelids closing faster than the (negative) threshold and reopening
/// within a few frames.
public struct BlinkDetector: Sendable {
    public enum Phase: Sendable, Equatable {
        case idle
        case closing(startFrame: Int)
    }

    /// Minimum frames between two blinks.
    public static let refractoryFrames = 5
    /// The eyes must reopen within this many frames of closing.
    public static let reopenWindow = 4
    /// A closure that lasts longer than this is discarded.
    public static let maximumDuration = 8

    public private(set) var phase: Phase = .idle
    public private(set) var lastBlinkFrame = 0
    /// Threshold frozen while a closure is being tracked.
    public private(set) var latchedThreshold = 0.0

    public init() {}

    public mutating func process(leftEyelidDiff: Double, rightEyelidDiff: Double, thresholds: Thresholds, context: FrameContext) -> GestureEvent? {
        if phase == .idle {
            latchedThreshold = thresholds.blink
        }
        let threshold = latchedThreshold
        let frame = context.frame
        var event: GestureEvent?

        switch phase {
        case .idle:
            if frame - lastBlinkFrame > BlinkDetector.refractoryFrames,
               leftEyelidDiff < threshold, rightEyelidDiff < threshold {
                phase = .closing(startFrame: frame)
            }
        case .closing(let startFrame):
            if leftEyelidDiff > -threshold, rightEyelidDiff > -threshold, frame - startFrame <= BlinkDetector.reopenWindow {
                event = .blink
                lastBlinkFrame = frame
                phase = .idle
            }
        }

        if case .closing(let startFrame) = phase, frame - startFrame > BlinkDetector.maximumDuration {
            phase = .idle
        }
        return event
    }

    public mutating func reset() {
        phase = .idle
    }
}
