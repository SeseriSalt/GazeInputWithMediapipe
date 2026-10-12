import Foundation

/// Which eye performed a wink. Naming follows the original flag semantics:
/// `.left` was reported as input code -1, `.right` as -2.
public enum Eye: Sendable, Equatable {
    case left
    case right
}

/// Corner the user glanced at. The raw value is the vowel index in `KeyboardLayout` rows.
public enum GlanceDirection: Int, Sendable, Equatable, CaseIterable {
    case upperLeft = 1
    case upperRight = 2
    case lowerLeft = 3
    case lowerRight = 4

    public var vowelIndex: Int { rawValue }
}

/// A recognized eye gesture.
public enum GestureEvent: Sendable, Equatable {
    case blink
    case wink(Eye)
    case glance(GlanceDirection)

    /// Numeric code compatible with the CSV logs of the original app
    /// (0 = blink, -1/-2 = wink, 1...4 = glance).
    public var legacyCode: Int {
        switch self {
        case .blink: return 0
        case .wink(.left): return -1
        case .wink(.right): return -2
        case .glance(let direction): return direction.rawValue
        }
    }
}

/// Frame bookkeeping shared by all detectors: refractory periods are expressed as
/// "frames since the last event of each kind".
public struct FrameContext: Sendable, Equatable {
    public var frame: Int
    public var lastBlinkFrame: Int
    public var lastWinkFrame: Int
    public var lastGlanceFrame: Int
    public var lastRegionChangeFrame: Int

    public init(frame: Int = 0, lastBlinkFrame: Int = 0, lastWinkFrame: Int = 0, lastGlanceFrame: Int = 0, lastRegionChangeFrame: Int = 0) {
        self.frame = frame
        self.lastBlinkFrame = lastBlinkFrame
        self.lastWinkFrame = lastWinkFrame
        self.lastGlanceFrame = lastGlanceFrame
        self.lastRegionChangeFrame = lastRegionChangeFrame
    }
}

/// Detector phase shared by the wink and glance state machines.
public enum DetectorPhase: Sendable, Equatable {
    /// Waiting for the waveform to cross a threshold.
    case idle
    /// Accumulating the area of an excursion beyond the threshold.
    case tracking
    /// The excursion was matched with an opposite one; an event is emitted this frame.
    case paired
}
