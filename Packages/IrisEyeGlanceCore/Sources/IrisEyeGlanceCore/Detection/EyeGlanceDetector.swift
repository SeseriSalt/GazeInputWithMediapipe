import CoreGraphics
import Foundation

/// Input to the glance detector: iris motion of both eyes with head motion removed,
/// plus the vertical head motion used to attenuate the waveform.
public struct GlanceSample: Sendable, Equatable {
    public var leftIrisDelta: CGPoint
    public var rightIrisDelta: CGPoint
    public var referenceDeltaY: Double

    public init(leftIrisDelta: CGPoint, rightIrisDelta: CGPoint, referenceDeltaY: Double) {
        self.leftIrisDelta = leftIrisDelta
        self.rightIrisDelta = rightIrisDelta
        self.referenceDeltaY = referenceDeltaY
    }
}

/// Per-frame output of the glance detector (waveform values are kept for logging).
public struct GlanceOutput: Sendable, Equatable {
    public var glanceDistance: Double
    public var directionDistance: Double
    public var correction: Double
    public var event: GestureEvent?

    public init(glanceDistance: Double, directionDistance: Double, correction: Double, event: GestureEvent?) {
        self.glanceDistance = glanceDistance
        self.directionDistance = directionDistance
        self.correction = correction
        self.event = event
    }
}

/// Detects an "eye glance": a quick look toward a screen corner and back.
///
/// The vertical waveform is the averaged iris y motion. Looking up produces a negative
/// excursion, returning produces a positive one. Each excursion is integrated; when an
/// excursion closes, the detector pairs it with an opposite excursion within `pairWindow`
/// frames. The horizontal direction is taken from the x motion at the stronger peak.
public struct EyeGlanceDetector: Sendable {
    public struct Segment: Sendable, Equatable {
        public var frame: Int
        public var area: Double
        public var direction: Double
        public var iris: LRPair
        public var isUsed: Bool
    }

    /// Left/right eye x deltas captured at a peak.
    public struct LRPair: Sendable, Equatable {
        public var left: Double
        public var right: Double
        public static let zero = LRPair(left: 0, right: 0)

        /// The eye with the larger movement is the more reliable one.
        public var dominant: Double {
            abs(left) > abs(right) ? left : right
        }
    }

    public static let warmupFrames = 15
    public static let refractoryFrames = 6
    public static let pairWindow = 15
    /// Base of the exponential attenuation applied when the head moves vertically.
    public static let correctionBase = 0.9057236643
    public static let waveformGain = 800.0
    public static let directionGain = 100_000.0

    /// Negative-excursion state machine (originally `glanceDownFlag`).
    public private(set) var downPhase: DetectorPhase = .idle
    /// Positive-excursion state machine (originally `glanceUpFlag`).
    public private(set) var upPhase: DetectorPhase = .idle
    public private(set) var areaUp = 0.0
    public private(set) var areaDown = 0.0
    public private(set) var lastGlanceFrame = 0

    private var firstFrame = 0
    private var endFrame = 0
    private var directionUp = 0.0
    private var directionDown = 0.0
    private var irisUp = LRPair.zero
    private var irisDown = LRPair.zero
    private var upSegments: [Segment] = []
    private var downSegments: [Segment] = []

    private var latchedMin = 0.0
    private var latchedMax = 0.0
    private var latchedAreaUp = 0.0
    private var latchedAreaDown = 0.0

    public init() {}

    /// Waveform value for a sample, optionally with a different attenuation base
    /// (the calibration flow uses its own).
    public static func waveform(_ sample: GlanceSample, correctionBase: Double = correctionBase) -> (distance: Double, correction: Double) {
        let correction = pow(correctionBase, abs(sample.referenceDeltaY) * 1000)
        let distance = (sample.leftIrisDelta.y + sample.rightIrisDelta.y) / 2 * waveformGain * correction
        return (distance, correction)
    }

    public mutating func process(_ sample: GlanceSample, thresholds: Thresholds, winkAreasWithinLimits: Bool, context: FrameContext) -> GlanceOutput {
        let (distance, correction) = EyeGlanceDetector.waveform(sample)
        let direction = sample.leftIrisDelta.x * sample.rightIrisDelta.x * EyeGlanceDetector.directionGain
        let x = LRPair(left: sample.leftIrisDelta.x, right: sample.rightIrisDelta.x)

        if downPhase == .idle {
            latchedMin = thresholds.glanceMin
            latchedAreaDown = thresholds.glanceAreaDown
        }
        if upPhase == .idle {
            latchedMax = thresholds.glanceMax
            latchedAreaUp = thresholds.glanceAreaUp
        }

        let frame = context.frame
        let gateOpen = frame > EyeGlanceDetector.warmupFrames
            && frame - lastGlanceFrame > EyeGlanceDetector.refractoryFrames
            && frame - context.lastRegionChangeFrame > EyeGlanceDetector.refractoryFrames
            && frame - context.lastBlinkFrame > EyeGlanceDetector.refractoryFrames
            && frame - context.lastWinkFrame > EyeGlanceDetector.refractoryFrames

        var event: GestureEvent?
        if gateOpen {
            event = detect(distance: distance, direction: direction, x: x, winkAreasWithinLimits: winkAreasWithinLimits, frame: frame)
        } else {
            reset()
        }
        return GlanceOutput(glanceDistance: distance, directionDistance: direction, correction: correction, event: event)
    }

    private mutating func detect(distance: Double, direction: Double, x: LRPair, winkAreasWithinLimits: Bool, frame: Int) -> GestureEvent? {
        let minimum = latchedMin
        let maximum = latchedMax
        let areaUpThreshold = latchedAreaUp
        let areaDownThreshold = latchedAreaDown
        let frameLimit = frame - EyeGlanceDetector.pairWindow

        // Negative excursion (eye moved up on screen)
        if downPhase == .idle, distance < minimum {
            downPhase = .tracking
            firstFrame = frame
            directionDown = direction
            irisDown = x
            areaDown += distance
            endFrame = frame
        } else if downPhase == .tracking, distance < minimum {
            areaDown += distance
            endFrame = frame
            if directionDown < direction {
                directionDown = direction
                irisDown = x
            }
        } else if downPhase == .tracking, distance > minimum {
            downSegments.insert(Segment(frame: endFrame, area: areaDown, direction: directionDown, iris: irisDown, isUsed: false), at: 0)
            var paired = false
            if areaDown < areaDownThreshold, winkAreasWithinLimits {
                upSegments.removeAll { $0.frame < frameLimit }
                if let index = upSegments.firstIndex(where: { $0.area > areaUpThreshold && !$0.isUsed }) {
                    paired = true
                    downSegments[0].isUsed = true
                    upSegments[index].isUsed = true
                    directionUp = upSegments[index].direction
                    irisUp = upSegments[index].iris
                }
            }
            if paired {
                downPhase = .paired
            } else {
                downPhase = .idle
                directionDown = 0
                irisDown = .zero
            }
            endFrame = 0
            areaDown = 0
        }

        // Positive excursion (eye moved down on screen)
        if upPhase == .idle, distance > maximum {
            upPhase = .tracking
            firstFrame = frame
            directionUp = direction
            irisUp = x
            areaUp += distance
            endFrame = frame
        } else if upPhase == .tracking, distance > maximum {
            areaUp += distance
            endFrame = frame
            if directionUp < direction {
                directionUp = direction
                irisUp = x
            }
        } else if upPhase == .tracking, distance < maximum {
            upSegments.insert(Segment(frame: endFrame, area: areaUp, direction: directionUp, iris: irisUp, isUsed: false), at: 0)
            var paired = false
            if areaUp > areaUpThreshold, winkAreasWithinLimits {
                downSegments.removeAll { $0.frame < frameLimit }
                if let index = downSegments.firstIndex(where: { $0.area < areaDownThreshold && !$0.isUsed }) {
                    paired = true
                    upSegments[0].isUsed = true
                    downSegments[index].isUsed = true
                    directionDown = downSegments[index].direction
                    irisDown = downSegments[index].iris
                }
            }
            if paired {
                upPhase = .paired
            } else {
                upPhase = .idle
                directionUp = 0
                irisUp = .zero
            }
            endFrame = 0
            areaUp = 0
        }

        if upPhase == .paired, let event = resolve(leftSymbol: .upperLeft, rightSymbol: .upperRight, frame: frame) {
            return event
        }
        if downPhase == .paired, let event = resolve(leftSymbol: .lowerLeft, rightSymbol: .lowerRight, frame: frame) {
            return event
        }
        return nil
    }

    /// Chooses left or right from the x motion at the stronger of the two peaks.
    private mutating func resolve(leftSymbol: GlanceDirection, rightSymbol: GlanceDirection, frame: Int) -> GestureEvent? {
        let symbol: GlanceDirection
        if downPhase == .paired {
            if directionUp > directionDown {
                symbol = irisUp.dominant < 0 ? leftSymbol : rightSymbol
            } else {
                symbol = irisDown.dominant > 0 ? leftSymbol : rightSymbol
            }
        } else {
            if directionUp > directionDown {
                symbol = irisUp.dominant > 0 ? leftSymbol : rightSymbol
            } else {
                symbol = irisDown.dominant < 0 ? leftSymbol : rightSymbol
            }
        }
        lastGlanceFrame = frame
        reset()
        return .glance(symbol)
    }

    /// Clears the in-progress excursions but keeps the recent segment history,
    /// matching the original `glanceInit()`.
    public mutating func reset() {
        upPhase = .idle
        downPhase = .idle
        firstFrame = 0
        endFrame = 0
        directionUp = 0
        directionDown = 0
        irisUp = .zero
        irisDown = .zero
        areaUp = 0
        areaDown = 0
    }
}
