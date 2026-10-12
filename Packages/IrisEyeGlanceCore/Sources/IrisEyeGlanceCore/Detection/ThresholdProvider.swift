import Foundation

/// Thresholds for one frame, derived from the current depth and the user parameters.
public struct Thresholds: Equatable, Sendable {
    public var glanceMax: Double
    public var glanceMin: Double
    public var glanceAreaUp: Double
    public var glanceAreaDown: Double
    public var winkMax: Double
    public var winkMin: Double
    public var winkAreaMultiplier: Double
    public var eyelidHeight: Double
    public var blink: Double

    public var winkAreaMax: Double { winkMax * winkAreaMultiplier }
    public var winkAreaMin: Double { winkMin * winkAreaMultiplier }

    public init(glanceMax: Double, glanceMin: Double, glanceAreaUp: Double, glanceAreaDown: Double,
                winkMax: Double, winkMin: Double, winkAreaMultiplier: Double, eyelidHeight: Double, blink: Double) {
        self.glanceMax = glanceMax
        self.glanceMin = glanceMin
        self.glanceAreaUp = glanceAreaUp
        self.glanceAreaDown = glanceAreaDown
        self.winkMax = winkMax
        self.winkMin = winkMin
        self.winkAreaMultiplier = winkAreaMultiplier
        self.eyelidHeight = eyelidHeight
        self.blink = blink
    }
}

/// Depth-dependent threshold model. The linear coefficients were fitted experimentally
/// and are kept identical to the original implementation.
public enum ThresholdProvider {
    public static let glanceDepthSlope = 0.001
    public static let winkDepthSlope = -0.011
    public static let winkMinRatio = 0.96
    public static let eyelidHeightSlope = -0.03
    public static let eyelidHeightOffset = 23.0
    public static let blinkOffset = 2.0

    public static func thresholds(depth: Double, parameters: DetectionParameters) -> Thresholds {
        let glanceMin = glanceDepthSlope * depth - parameters.glanceThreshold
        let glanceMax = -glanceMin
        let winkMax = winkDepthSlope * depth + parameters.winkThreshold
        let winkMin = -winkMax * winkMinRatio
        return Thresholds(
            glanceMax: glanceMax,
            glanceMin: glanceMin,
            glanceAreaUp: glanceMax * parameters.glanceIntegralMultiplier,
            glanceAreaDown: glanceMin * parameters.glanceIntegralMultiplier,
            winkMax: winkMax,
            winkMin: winkMin,
            winkAreaMultiplier: parameters.winkAreaMultiplier,
            eyelidHeight: eyelidHeightSlope * depth + eyelidHeightOffset,
            blink: -winkMax - blinkOffset
        )
    }
}
