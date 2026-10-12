import Foundation

/// Values produced by the automatic calibration.
public struct CalibrationResult: Sendable, Equatable {
    public var glanceThreshold: Double
    public var glanceIntegralMultiplier: Double

    public init(glanceThreshold: Double, glanceIntegralMultiplier: Double) {
        self.glanceThreshold = glanceThreshold
        self.glanceIntegralMultiplier = glanceIntegralMultiplier
    }
}

/// State machine for the automatic calibration flow.
///
/// 1. Rest: the user stares at a fixed point; the glance waveform extremes give the
///    waveform threshold.
/// 2. Arrows: the user glances toward eight arrows; the integrated areas give the
///    integral multiplier.
public struct Calibrator: Sendable {
    public enum Step: Sendable, Equatable {
        case idle
        case restIntro
        case restCollecting
        case glanceIntro
        case arrow(Int)
        case finishing
        case done

        /// Frames are logged to CSV only while the user is actually performing the task.
        public var shouldLogFrames: Bool {
            switch self {
            case .idle, .restCollecting, .arrow: return true
            case .restIntro, .glanceIntro, .finishing, .done: return false
            }
        }
    }

    public static let arrowCount = 8
    /// Attenuation base used for the calibration waveform (differs from detection).
    public static let correctionBase = 0.8865681506
    /// Margin added above the resting extremes.
    public static let restMargin = 0.1
    /// Margin subtracted from the glance extremes.
    public static let areaMargin = 0.1
    /// Number of arrow samples averaged (the weakest glances).
    public static let averagedSamples = 4

    public private(set) var step: Step = .idle
    public private(set) var glanceThreshold: Double?
    public private(set) var result: CalibrationResult?

    private var restMaximum = 0.0
    private var restMinimum = 0.0
    private var arrowMaxima = Array(repeating: 0.0, count: arrowCount)
    private var arrowMinima = Array(repeating: 0.0, count: arrowCount)

    public init() {}

    public var isActive: Bool { step != .idle }

    /// Advances to the next step (the calibration button was pressed).
    public mutating func advance() {
        switch step {
        case .idle:
            step = .restIntro
            glanceThreshold = nil
            result = nil
            restMaximum = 0
            restMinimum = 0
            arrowMaxima = Array(repeating: 0, count: Calibrator.arrowCount)
            arrowMinima = Array(repeating: 0, count: Calibrator.arrowCount)
        case .restIntro:
            step = .restCollecting
        case .restCollecting:
            step = .glanceIntro
        case .glanceIntro:
            step = .arrow(0)
        case .arrow(let index):
            step = index + 1 < Calibrator.arrowCount ? .arrow(index + 1) : .finishing
        case .finishing:
            step = .done
        case .done:
            step = .idle
        }
    }

    /// Feeds one frame of measurements. `areaUp` / `areaDown` are the glance detector's
    /// current integrated areas.
    public mutating func record(glanceDistance: Double, areaUp: Double, areaDown: Double) {
        switch step {
        case .restCollecting:
            restMaximum = max(restMaximum, glanceDistance)
            restMinimum = min(restMinimum, glanceDistance)

        case .glanceIntro:
            let maximum = Calibrator.round1(restMaximum)
            let minimum = abs(Calibrator.round1(restMinimum))
            glanceThreshold = min(maximum, minimum) + Calibrator.restMargin

        case .arrow(let index):
            arrowMaxima[index] = max(arrowMaxima[index], areaUp)
            arrowMinima[index] = min(arrowMinima[index], areaDown)

        case .finishing:
            let threshold = glanceThreshold ?? DetectionParameters().glanceThreshold
            let averageMaximum = Calibrator.round1(Calibrator.average(arrowMaxima.sorted().prefix(Calibrator.averagedSamples)))
            let averageMinimum = abs(Calibrator.round1(Calibrator.average(arrowMinima.sorted(by: >).prefix(Calibrator.averagedSamples))))
            let weakest = min(averageMaximum, averageMinimum)
            let multiplier = Calibrator.round1((weakest - Calibrator.areaMargin) / threshold)
            result = CalibrationResult(glanceThreshold: threshold, glanceIntegralMultiplier: multiplier)
            step = .done

        case .idle, .restIntro, .done:
            break
        }
    }

    private static func round1(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    private static func average(_ values: ArraySlice<Double>) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}
