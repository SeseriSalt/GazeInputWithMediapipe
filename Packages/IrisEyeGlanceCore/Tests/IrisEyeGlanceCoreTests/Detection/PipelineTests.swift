import Foundation
import Testing
@testable import IrisEyeGlanceCore

@Suite("Eye input pipeline")
struct EyeInputPipelineTests {

    private func features(frame: Int, eyelidDiff: Double = 0, lrDiff: Double = 0, glanceY: Double = 0, glanceX: Double = 0) -> EyeFeatures {
        var features = EyeFeatures()
        features.frame = frame
        features.leftEyelidDiff = eyelidDiff
        features.rightEyelidDiff = eyelidDiff
        features.eyelidDiffLR = lrDiff
        features.leftIrisMinusReferenceDelta2 = CGPoint(x: glanceX, y: glanceY)
        features.rightIrisMinusReferenceDelta2 = CGPoint(x: glanceX, y: glanceY)
        features.thresholdDepth = 0
        return features
    }

    @Test("Blink is reported and recorded as the last blink frame")
    func blink() {
        var pipeline = EyeInputPipeline(parameters: DetectionParameters())
        _ = pipeline.process(features(frame: 20, eyelidDiff: -9))
        let result = pipeline.process(features(frame: 21, eyelidDiff: 9))
        #expect(result.event == .blink)
        #expect(pipeline.context.lastBlinkFrame == 21)
    }

    @Test("Wink is not evaluated during the refractory period after a blink")
    func refractoryAfterBlink() {
        var pipeline = EyeInputPipeline(parameters: DetectionParameters())
        _ = pipeline.process(features(frame: 20, eyelidDiff: -9))
        _ = pipeline.process(features(frame: 21, eyelidDiff: 9))
        var events: [GestureEvent] = []
        for (offset, lr) in [-7.0, -9, -8, 0, 8, 10, 9, 0].enumerated() {
            let result = pipeline.process(features(frame: 22 + offset, lrDiff: lr))
            if let event = result.event { events.append(event) }
        }
        #expect(events.isEmpty)
    }

    @Test("Wink is detected after the refractory period and resets the other detectors")
    func winkAfterRefractory() {
        var pipeline = EyeInputPipeline(parameters: DetectionParameters())
        var events: [GestureEvent] = []
        for (offset, lr) in [-7.0, -9, -8, 0, 8, 10, 9, 0].enumerated() {
            let result = pipeline.process(features(frame: 30 + offset, lrDiff: lr))
            if let event = result.event { events.append(event) }
        }
        #expect(events == [.wink(.right)])
        #expect(pipeline.context.lastWinkFrame == 37)
        #expect(pipeline.glanceDetector.upPhase == .idle)
    }

    @Test("Parameters can be replaced at runtime")
    func updateParameters() {
        var pipeline = EyeInputPipeline(parameters: DetectionParameters())
        var parameters = DetectionParameters()
        parameters.glanceThreshold = 2.0
        pipeline.parameters = parameters
        let result = pipeline.process(features(frame: 1))
        #expect(abs(result.thresholds.glanceMin - (-2.0)) < 1e-9)
    }

    @Test("Region change frame feeds the glance gate")
    func regionChange() {
        var pipeline = EyeInputPipeline(parameters: DetectionParameters())
        pipeline.noteRegionChange(atFrame: 40)
        #expect(pipeline.context.lastRegionChangeFrame == 40)
    }
}
