import Foundation
import Testing
@testable import IrisEyeGlanceCore

@Suite("Calibrator")
struct CalibratorTests {

    @Test("Starts idle and walks through the rest and arrow steps")
    func flow() {
        var calibrator = Calibrator()
        #expect(calibrator.step == .idle)
        calibrator.advance()
        #expect(calibrator.step == .restIntro)
        calibrator.advance()
        #expect(calibrator.step == .restCollecting)
        calibrator.advance()
        #expect(calibrator.step == .glanceIntro)
        calibrator.advance()
        #expect(calibrator.step == .arrow(0))
        for _ in 0..<7 { calibrator.advance() }
        #expect(calibrator.step == .arrow(7))
        calibrator.advance()
        #expect(calibrator.step == .finishing)
    }

    @Test("Rest and arrow samples produce the glance threshold and integral multiplier")
    func result() throws {
        var calibrator = Calibrator()
        calibrator.advance() // restIntro
        calibrator.advance() // restCollecting
        calibrator.record(glanceDistance: 0.6, areaUp: 0, areaDown: 0)
        calibrator.record(glanceDistance: -0.4, areaUp: 0, areaDown: 0)
        calibrator.advance() // glanceIntro: computes rest threshold on next sample
        calibrator.record(glanceDistance: 0, areaUp: 0, areaDown: 0)
        let threshold = try #require(calibrator.glanceThreshold)
        #expect(abs(threshold - 0.5) < 1e-9)

        calibrator.advance() // arrow(0)
        for _ in 0..<8 {
            calibrator.record(glanceDistance: 0, areaUp: 6.0, areaDown: -7.0)
            calibrator.advance()
        }
        #expect(calibrator.step == .finishing)
        calibrator.record(glanceDistance: 0, areaUp: 0, areaDown: 0)
        #expect(calibrator.step == .done)
        let result = try #require(calibrator.result)
        #expect(abs(result.glanceThreshold - 0.5) < 1e-9)
        #expect(abs(result.glanceIntegralMultiplier - 11.8) < 1e-9)
    }

    @Test("Advancing from done returns to idle")
    func close() {
        var calibrator = Calibrator()
        calibrator.advance()
        calibrator.advance()
        calibrator.advance()
        calibrator.record(glanceDistance: 0, areaUp: 0, areaDown: 0)
        for _ in 0..<9 { calibrator.advance() }
        calibrator.record(glanceDistance: 0, areaUp: 0, areaDown: 0)
        #expect(calibrator.step == .done)
        calibrator.advance()
        #expect(calibrator.step == .idle)
        #expect(!calibrator.isActive)
    }

    @Test("Recording is skipped for steps that should not be logged")
    func logging() {
        var calibrator = Calibrator()
        #expect(calibrator.step.shouldLogFrames)
        calibrator.advance() // restIntro
        #expect(!calibrator.step.shouldLogFrames)
        calibrator.advance() // restCollecting
        #expect(calibrator.step.shouldLogFrames)
    }
}
