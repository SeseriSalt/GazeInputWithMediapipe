import Foundation
import Testing
@testable import IrisEyeGlanceCore

/// Shared helpers that drive detectors with synthetic waveforms.
enum DetectorFixtures {
    static let parameters = DetectionParameters()
    /// Depth 0 gives wink ±6.2 / -5.952, blink -8.2, glance ±0.9, glance areas ±4.5.
    static let thresholds = ThresholdProvider.thresholds(depth: 0, parameters: parameters)

    static func context(frame: Int, lastBlink: Int = 0, lastWink: Int = 0, lastGlance: Int = 0, lastRegionChange: Int = 0) -> FrameContext {
        FrameContext(frame: frame, lastBlinkFrame: lastBlink, lastWinkFrame: lastWink, lastGlanceFrame: lastGlance, lastRegionChangeFrame: lastRegionChange)
    }
}

@Suite("Blink detector")
struct BlinkDetectorTests {

    @Test("Both eyelids closing then opening within four frames is a blink")
    func blink() {
        var detector = BlinkDetector()
        let t = DetectorFixtures.thresholds
        #expect(detector.process(leftEyelidDiff: -9, rightEyelidDiff: -9, thresholds: t, context: DetectorFixtures.context(frame: 20)) == nil)
        #expect(detector.process(leftEyelidDiff: 9, rightEyelidDiff: 9, thresholds: t, context: DetectorFixtures.context(frame: 21)) == .blink)
        #expect(detector.lastBlinkFrame == 21)
    }

    @Test("A closure that never reopens is discarded after the time limit")
    func timeout() {
        var detector = BlinkDetector()
        let t = DetectorFixtures.thresholds
        _ = detector.process(leftEyelidDiff: -9, rightEyelidDiff: -9, thresholds: t, context: DetectorFixtures.context(frame: 20))
        for frame in 21...29 {
            #expect(detector.process(leftEyelidDiff: 0, rightEyelidDiff: 0, thresholds: t, context: DetectorFixtures.context(frame: frame)) == nil)
        }
        #expect(detector.phase == .idle)
    }

    @Test("Only one eyelid closing is not a blink")
    func oneEye() {
        var detector = BlinkDetector()
        let t = DetectorFixtures.thresholds
        #expect(detector.process(leftEyelidDiff: -9, rightEyelidDiff: 0, thresholds: t, context: DetectorFixtures.context(frame: 20)) == nil)
        #expect(detector.process(leftEyelidDiff: 9, rightEyelidDiff: 0, thresholds: t, context: DetectorFixtures.context(frame: 21)) == nil)
    }
}

@Suite("Wink detector")
struct WinkDetectorTests {

    private func run(_ samples: [Double], startFrame: Int = 16) -> (events: [GestureEvent], detector: WinkDetector) {
        var detector = WinkDetector()
        var events: [GestureEvent] = []
        var previous = 0.0
        for (offset, sample) in samples.enumerated() {
            let frame = startFrame + offset
            if let event = detector.process(eyelidDiffLR: sample, previousEyelidDiffLR: previous, thresholds: DetectorFixtures.thresholds, context: DetectorFixtures.context(frame: frame)) {
                events.append(event)
            }
            previous = sample
        }
        return (events, detector)
    }

    @Test("Negative peak followed by a positive peak reports a right wink")
    func negativeThenPositive() {
        let (events, _) = run([-7, -9, -8, 0, 8, 10, 9, 0])
        #expect(events == [.wink(.right)])
    }

    @Test("Positive peak followed by a negative peak reports a left wink")
    func positiveThenNegative() {
        let (events, _) = run([8, 10, 9, 0, -7, -9, -8, 0])
        #expect(events == [.wink(.left)])
    }

    @Test("Peaks whose integrated area is too small are ignored")
    func smallArea() {
        let (events, _) = run([-7, 0, 8, 0])
        #expect(events.isEmpty)
    }

    @Test("Nothing is detected before the warm-up window")
    func warmup() {
        let (events, _) = run([-7, -9, -8, 0, 8, 10, 9, 0], startFrame: 1)
        #expect(events.isEmpty)
    }

    @Test("A peak that lasts too long is reset")
    func longPeak() {
        let (events, detector) = run([-7, -9, -9, -9, -9, -9, -9, -9, -9])
        #expect(events.isEmpty)
        #expect(detector.leftPhase == .idle)
    }
}

@Suite("Eye glance detector")
struct EyeGlanceDetectorTests {

    private func sample(y: Double, x: Double) -> GlanceSample {
        GlanceSample(leftIrisDelta: CGPoint(x: x, y: y), rightIrisDelta: CGPoint(x: x, y: y), referenceDeltaY: 0)
    }

    private func run(_ samples: [GlanceSample], startFrame: Int = 16) -> [GestureEvent] {
        var detector = EyeGlanceDetector()
        var events: [GestureEvent] = []
        for (offset, sample) in samples.enumerated() {
            let output = detector.process(sample, thresholds: DetectorFixtures.thresholds, winkAreasWithinLimits: true, context: DetectorFixtures.context(frame: startFrame + offset))
            if let event = output.event { events.append(event) }
        }
        return events
    }

    @Test("Waveform is scaled by 800 and corrected for head movement")
    func waveform() {
        var detector = EyeGlanceDetector()
        let output = detector.process(sample(y: -0.0025, x: 0), thresholds: DetectorFixtures.thresholds, winkAreasWithinLimits: true, context: DetectorFixtures.context(frame: 1))
        #expect(abs(output.glanceDistance - (-2)) < 1e-9)
        #expect(output.correction == 1)

        let moved = detector.process(GlanceSample(leftIrisDelta: CGPoint(x: 0, y: -0.0025), rightIrisDelta: CGPoint(x: 0, y: -0.0025), referenceDeltaY: 0.001), thresholds: DetectorFixtures.thresholds, winkAreasWithinLimits: true, context: DetectorFixtures.context(frame: 2))
        #expect(moved.correction < 1)
    }

    @Test("Eye moves up then returns: upper-left glance when x deltas are negative")
    func upperLeft() {
        let up = sample(y: -0.0025, x: -0.01)     // dist -2, direction 10
        let upBig = sample(y: -0.00375, x: -0.01) // dist -3
        let back = sample(y: 0.0025, x: 0.005)    // dist +2, direction 2.5
        let backBig = sample(y: 0.00375, x: 0.005)
        let rest = sample(y: 0, x: 0)
        let events = run([up, upBig, up, rest, back, backBig, back, rest])
        #expect(events == [.glance(.upperLeft)])
    }

    @Test("Eye moves up then returns: upper-right glance when x deltas are positive")
    func upperRight() {
        let up = sample(y: -0.0025, x: 0.01)
        let upBig = sample(y: -0.00375, x: 0.01)
        let back = sample(y: 0.0025, x: 0.005)
        let backBig = sample(y: 0.00375, x: 0.005)
        let rest = sample(y: 0, x: 0)
        // direction = x*x*1e5 is positive for both, the sign of the larger |x| decides
        let events = run([up, upBig, up, rest, back, backBig, back, rest])
        #expect(events == [.glance(.upperRight)])
    }

    @Test("Eye moves down then returns: lower glance")
    func lower() {
        let down = sample(y: 0.0025, x: 0.01)
        let downBig = sample(y: 0.00375, x: 0.01)
        let back = sample(y: -0.0025, x: 0.005)
        let backBig = sample(y: -0.00375, x: 0.005)
        let rest = sample(y: 0, x: 0)
        let events = run([down, downBig, down, rest, back, backBig, back, rest])
        #expect(events == [.glance(.lowerRight)])
    }

    @Test("A single excursion without a return is not a glance")
    func noReturn() {
        let up = sample(y: -0.0025, x: 0.01)
        let rest = sample(y: 0, x: 0)
        #expect(run([up, up, up, rest, rest, rest]).isEmpty)
    }

    @Test("Glances are suppressed while a wink is accumulating area")
    func suppressedByWink() {
        var detector = EyeGlanceDetector()
        let up = sample(y: -0.0025, x: 0.01)
        let back = sample(y: 0.0025, x: 0.005)
        let rest = sample(y: 0, x: 0)
        var events: [GestureEvent] = []
        for (offset, s) in [up, up, up, rest, back, back, back, rest].enumerated() {
            let output = detector.process(s, thresholds: DetectorFixtures.thresholds, winkAreasWithinLimits: false, context: DetectorFixtures.context(frame: 16 + offset))
            if let event = output.event { events.append(event) }
        }
        #expect(events.isEmpty)
    }
}

@Suite("Glance direction")
struct GlanceDirectionTests {
    @Test("Directions map to vowel indices 1...4 in the keyboard rows")
    func vowelIndex() {
        #expect(GlanceDirection.upperLeft.vowelIndex == 1)
        #expect(GlanceDirection.upperRight.vowelIndex == 2)
        #expect(GlanceDirection.lowerLeft.vowelIndex == 3)
        #expect(GlanceDirection.lowerRight.vowelIndex == 4)
    }
}
