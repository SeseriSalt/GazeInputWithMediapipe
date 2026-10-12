import Foundation

/// Everything computed for one frame, for the UI and for logging.
public struct FrameResult: Sendable {
    public var features: EyeFeatures
    public var thresholds: Thresholds
    /// The gesture recognized this frame, if any. At most one gesture per frame.
    public var event: GestureEvent?
    public var glance: GlanceOutput
    public var winkAreaUp: Double
    public var winkAreaDown: Double

    public init(features: EyeFeatures, thresholds: Thresholds, event: GestureEvent?, glance: GlanceOutput, winkAreaUp: Double = 0, winkAreaDown: Double = 0) {
        self.features = features
        self.thresholds = thresholds
        self.event = event
        self.glance = glance
        self.winkAreaUp = winkAreaUp
        self.winkAreaDown = winkAreaDown
    }
}

/// Runs the three detectors in order (blink, wink, glance) and arbitrates between them:
/// an event from one detector resets the others and starts their refractory period.
public struct EyeInputPipeline: Sendable {
    public var parameters: DetectionParameters
    public private(set) var context = FrameContext()
    public private(set) var blinkDetector = BlinkDetector()
    public private(set) var winkDetector = WinkDetector()
    public private(set) var glanceDetector = EyeGlanceDetector()

    public init(parameters: DetectionParameters) {
        self.parameters = parameters
    }

    /// Call when the cursor moved to a different input region; glances are suppressed
    /// for a few frames afterwards because the eyes move with the cursor.
    public mutating func noteRegionChange(atFrame frame: Int) {
        context.lastRegionChangeFrame = frame
    }

    public mutating func process(_ features: EyeFeatures) -> FrameResult {
        context.frame = features.frame
        let thresholds = ThresholdProvider.thresholds(depth: features.thresholdDepth, parameters: parameters)

        var event: GestureEvent?

        if let blink = blinkDetector.process(leftEyelidDiff: features.leftEyelidDiff, rightEyelidDiff: features.rightEyelidDiff, thresholds: thresholds, context: context) {
            event = blink
            context.lastBlinkFrame = context.frame
            winkDetector.reset()
            glanceDetector.reset()
        }

        if let wink = winkDetector.process(eyelidDiffLR: features.eyelidDiffLR, previousEyelidDiffLR: features.previousEyelidDiffLR, thresholds: thresholds, context: context) {
            event = event ?? wink
            context.lastWinkFrame = context.frame
            blinkDetector.reset()
            glanceDetector.reset()
        }

        let glance = glanceDetector.process(features.glanceSample, thresholds: thresholds, winkAreasWithinLimits: winkDetector.areasWithinLimits, context: context)
        if let glanceEvent = glance.event {
            event = event ?? glanceEvent
            context.lastGlanceFrame = context.frame
            blinkDetector.reset()
            winkDetector.reset()
        }

        return FrameResult(features: features, thresholds: thresholds, event: event, glance: glance,
                           winkAreaUp: winkDetector.areaUp, winkAreaDown: winkDetector.areaDown)
    }

    /// Forgets all detector state and event history (used by the reset button).
    public mutating func reset() {
        context = FrameContext()
        blinkDetector = BlinkDetector()
        winkDetector = WinkDetector()
        glanceDetector = EyeGlanceDetector()
    }
}
