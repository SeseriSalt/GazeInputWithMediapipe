import Foundation

/// User-tunable detection parameters. The values are the ones that used to live in the
/// settings sliders; the UserDefaults keys are kept so existing devices keep their settings.
public struct DetectionParameters: Codable, Equatable, Sendable {
    /// Wink / blink waveform threshold at 0 mm (`winkSliderValue`).
    public var winkThreshold: Double = 6.2
    /// Multiplier applied to the wink threshold to obtain the integrated-area threshold.
    public var winkAreaMultiplier: Double = 2.8
    /// Eye-glance waveform threshold at 0 mm (`glanceSliderValue`).
    public var glanceThreshold: Double = 0.9
    /// Multiplier applied to the glance threshold to obtain the integrated-area threshold.
    public var glanceIntegralMultiplier: Double = 5.0

    public init() {}

    public init(winkThreshold: Double, winkAreaMultiplier: Double, glanceThreshold: Double, glanceIntegralMultiplier: Double) {
        self.winkThreshold = winkThreshold
        self.winkAreaMultiplier = winkAreaMultiplier
        self.glanceThreshold = glanceThreshold
        self.glanceIntegralMultiplier = glanceIntegralMultiplier
    }

    // MARK: Persistence

    public enum DefaultsKey {
        public static let winkThreshold = "winkSliderValue"
        public static let winkAreaMultiplier = "winkAreaSliderValue"
        public static let glanceThreshold = "glanceSliderValue"
        public static let glanceIntegralMultiplier = "integralSliderValue"
    }

    public init(userDefaults: UserDefaults) {
        let defaults = DetectionParameters()
        winkThreshold = userDefaults.object(forKey: DefaultsKey.winkThreshold) as? Double ?? defaults.winkThreshold
        winkAreaMultiplier = userDefaults.object(forKey: DefaultsKey.winkAreaMultiplier) as? Double ?? defaults.winkAreaMultiplier
        glanceThreshold = userDefaults.object(forKey: DefaultsKey.glanceThreshold) as? Double ?? defaults.glanceThreshold
        glanceIntegralMultiplier = userDefaults.object(forKey: DefaultsKey.glanceIntegralMultiplier) as? Double ?? defaults.glanceIntegralMultiplier
    }

    public func save(to userDefaults: UserDefaults) {
        userDefaults.set(winkThreshold, forKey: DefaultsKey.winkThreshold)
        userDefaults.set(winkAreaMultiplier, forKey: DefaultsKey.winkAreaMultiplier)
        userDefaults.set(glanceThreshold, forKey: DefaultsKey.glanceThreshold)
        userDefaults.set(glanceIntegralMultiplier, forKey: DefaultsKey.glanceIntegralMultiplier)
    }
}
