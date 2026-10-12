import Foundation
import Testing
@testable import IrisEyeGlanceCore

@Suite("Detection parameters")
struct DetectionParametersTests {

    @Test("Defaults match the previous slider defaults")
    func defaults() {
        let parameters = DetectionParameters()
        #expect(parameters.winkThreshold == 6.2)
        #expect(parameters.winkAreaMultiplier == 2.8)
        #expect(parameters.glanceThreshold == 0.9)
        #expect(parameters.glanceIntegralMultiplier == 5.0)
    }

    @Test("Round-trips through UserDefaults using the legacy keys")
    func persistence() throws {
        let suiteName = "DetectionParametersTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var parameters = DetectionParameters()
        parameters.winkThreshold = 7.1
        parameters.glanceThreshold = 1.2
        parameters.save(to: defaults)

        #expect(defaults.double(forKey: "winkSliderValue") == 7.1)
        #expect(defaults.double(forKey: "glanceSliderValue") == 1.2)

        let loaded = DetectionParameters(userDefaults: defaults)
        #expect(loaded == parameters)
    }

    @Test("Missing keys fall back to defaults")
    func fallback() throws {
        let suiteName = "DetectionParametersTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        #expect(DetectionParameters(userDefaults: defaults) == DetectionParameters())
    }
}

@Suite("Threshold provider")
struct ThresholdProviderTests {

    @Test("Thresholds at 300 mm reproduce the original ikichiDecision formulas")
    func thresholdsAt300mm() {
        let thresholds = ThresholdProvider.thresholds(depth: 300, parameters: DetectionParameters())
        #expect(abs(thresholds.glanceMin - (-0.6)) < 1e-9)
        #expect(abs(thresholds.glanceMax - 0.6) < 1e-9)
        #expect(abs(thresholds.glanceAreaUp - 3.0) < 1e-9)
        #expect(abs(thresholds.glanceAreaDown - (-3.0)) < 1e-9)
        #expect(abs(thresholds.winkMax - 2.9) < 1e-9)
        #expect(abs(thresholds.winkMin - (-2.784)) < 1e-9)
        #expect(abs(thresholds.eyelidHeight - 14.0) < 1e-9)
        #expect(abs(thresholds.blink - (-4.9)) < 1e-9)
    }

    @Test("Wink area thresholds scale the wink thresholds by the multiplier")
    func winkArea() {
        let thresholds = ThresholdProvider.thresholds(depth: 0, parameters: DetectionParameters())
        #expect(abs(thresholds.winkAreaMax - 6.2 * 2.8) < 1e-9)
        #expect(abs(thresholds.winkAreaMin - (-6.2 * 0.96 * 2.8)) < 1e-9)
    }
}
