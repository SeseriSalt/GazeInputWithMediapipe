import Foundation

/// Detects a wink from the waveform `leftEyelidDiff - rightEyelidDiff`.
///
/// A wink produces a negative excursion followed by a positive one (or vice versa).
/// Each excursion beyond the threshold is integrated; when an excursion closes, the
/// detector looks for an opposite excursion within `pairWindow` frames whose area also
/// exceeds its threshold. The two excursions form a pair and an event is emitted.
public struct WinkDetector: Sendable {
    public struct Segment: Sendable, Equatable {
        public var frame: Int
        public var area: Double
        public var isUsed: Bool
    }

    /// Frames to ignore after start-up.
    public static let warmupFrames = 15
    /// Frames to wait after any wink or blink.
    public static let refractoryFrames = 6
    /// Maximum distance in frames between the two excursions of a wink.
    public static let pairWindow = 15
    /// An excursion that does not close within this many frames is discarded.
    public static let maximumExcursionFrames = 7

    /// Negative excursion state machine (originally `winkUpFlag`).
    public private(set) var leftPhase: DetectorPhase = .idle
    /// Positive excursion state machine (originally `winkDownFlag`).
    public private(set) var rightPhase: DetectorPhase = .idle

    public private(set) var areaUp = 0.0
    public private(set) var areaDown = 0.0
    public private(set) var lastWinkFrame = 0
    public private(set) var latchedMin = 0.0
    public private(set) var latchedMax = 0.0

    private var minDiff = 0.0
    private var maxDiff = 0.0
    private var peakPrevious = 0.0
    private var peakNext = 0.0
    private var leftFirstFrame = 0
    private var rightFirstFrame = 0
    private var upSegments: [Segment] = []
    private var downSegments: [Segment] = []

    public init() {}

    /// True while the integrated areas are small enough that no wink is in progress.
    /// Used by the glance detector to avoid confusing the two gestures.
    public var areasWithinLimits: Bool {
        let multiplier = latchedMultiplier
        return areaUp > latchedMin * multiplier && areaDown < latchedMax * multiplier
    }
    private var latchedMultiplier = 1.0

    public mutating func process(eyelidDiffLR value: Double, previousEyelidDiffLR previous: Double, thresholds: Thresholds, context: FrameContext) -> GestureEvent? {
        if leftPhase == .idle { latchedMin = thresholds.winkMin }
        if rightPhase == .idle { latchedMax = thresholds.winkMax }
        latchedMultiplier = thresholds.winkAreaMultiplier

        let minimum = latchedMin
        let maximum = latchedMax
        let areaMin = minimum * thresholds.winkAreaMultiplier
        let areaMax = maximum * thresholds.winkAreaMultiplier
        let frame = context.frame
        let frameLimit = frame - WinkDetector.pairWindow
        var misjudged = false

        let gateOpen = frame > WinkDetector.warmupFrames
            && frame - lastWinkFrame > WinkDetector.refractoryFrames
            && frame - context.lastBlinkFrame > WinkDetector.refractoryFrames

        if gateOpen {
            // Negative excursion
            if leftPhase == .idle, value < minimum {
                leftPhase = .tracking
                minDiff = value
                peakPrevious = previous
                leftFirstFrame = frame
                areaUp += value
            } else if leftPhase == .tracking, value < minDiff {
                minDiff = value
                peakPrevious = previous
                areaUp += value
            } else if leftPhase == .tracking, value >= minDiff {
                if peakNext == 0 {
                    peakNext = value
                    areaUp += value
                }
                if value > minimum {
                    peakPrevious = 0
                    peakNext = 0
                    misjudged = false
                    upSegments.insert(Segment(frame: leftFirstFrame, area: areaUp, isUsed: false), at: 0)
                    var paired = false
                    if areaUp < areaMin {
                        downSegments.removeAll { $0.frame < frameLimit }
                        if let index = downSegments.firstIndex(where: { $0.area > areaMax && !$0.isUsed }) {
                            paired = true
                            upSegments[0].isUsed = true
                            downSegments[index].isUsed = true
                        }
                    }
                    leftPhase = paired ? .paired : .idle
                    leftFirstFrame = 0
                    areaUp = 0
                } else if !misjudged, peakPrevious * minDiff < 0, peakNext * minDiff < 0 {
                    misjudged = true
                }
            }

            // Positive excursion
            if rightPhase == .idle, value > maximum {
                rightPhase = .tracking
                maxDiff = value
                peakPrevious = previous
                rightFirstFrame = frame
                areaDown += value
            } else if rightPhase == .tracking, value > maxDiff {
                maxDiff = value
                peakPrevious = previous
                areaDown += value
            } else if rightPhase == .tracking, value <= maxDiff {
                if peakNext == 0 {
                    peakNext = value
                    areaDown += value
                }
                if value < maximum {
                    peakPrevious = 0
                    peakNext = 0
                    misjudged = false
                    downSegments.insert(Segment(frame: rightFirstFrame, area: areaDown, isUsed: false), at: 0)
                    var paired = false
                    if areaDown > areaMax {
                        upSegments.removeAll { $0.frame < frameLimit }
                        if let index = upSegments.firstIndex(where: { $0.area < areaMin && !$0.isUsed }) {
                            paired = true
                            downSegments[0].isUsed = true
                            upSegments[index].isUsed = true
                        }
                    }
                    rightPhase = paired ? .paired : .idle
                    rightFirstFrame = 0
                    areaDown = 0
                } else if !misjudged, peakPrevious * maxDiff < 0, peakNext * maxDiff < 0 {
                    misjudged = true
                }
            }
        }

        var event: GestureEvent?
        if leftPhase == .paired || rightPhase == .paired {
            event = .wink(leftPhase == .paired ? .left : .right)
            lastWinkFrame = frame
            reset()
        }

        if misjudged {
            reset()
        }
        if leftPhase != .idle, frame - leftFirstFrame > WinkDetector.maximumExcursionFrames {
            reset()
        }
        if rightPhase != .idle, frame - rightFirstFrame > WinkDetector.maximumExcursionFrames {
            reset()
        }
        return event
    }

    /// Clears the in-progress excursion but keeps the recent segment history,
    /// matching the original `winkInit()`.
    public mutating func reset() {
        leftPhase = .idle
        rightPhase = .idle
        minDiff = 0
        maxDiff = 0
        peakPrevious = 0
        peakNext = 0
        leftFirstFrame = 0
        rightFirstFrame = 0
        areaUp = 0
        areaDown = 0
    }
}
