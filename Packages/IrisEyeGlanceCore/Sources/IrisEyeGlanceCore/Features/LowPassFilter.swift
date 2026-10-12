import Foundation

/// First-order IIR low-pass filter.
public struct LowPassFilter: Sendable {
    private let alpha: Double
    private var lastValue: Double?

    public init(cutoffFrequency: Double, sampleRate: Double) {
        let dt = 1.0 / sampleRate
        let rc = 1.0 / (cutoffFrequency * 2 * .pi)
        alpha = dt / (dt + rc)
    }

    public mutating func filter(_ value: Double) -> Double {
        guard let last = lastValue else {
            lastValue = value
            return value
        }
        let filtered = alpha * value + (1 - alpha) * last
        lastValue = filtered
        return filtered
    }

    public mutating func reset() {
        lastValue = nil
    }
}
