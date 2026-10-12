import CoreGraphics
import Foundation

/// Rescales the x coordinate of a landmark into the range observed during the original
/// calibration of the camera framing. The y coordinate is passed through unchanged.
public struct LandmarkNormalizer: Sendable {
    public var minimumX: Double
    public var maximumX: Double

    public init(minimumX: Double = 0.08978804, maximumX: Double = 0.9095595) {
        self.minimumX = minimumX
        self.maximumX = maximumX
    }

    public func normalize(_ point: CGPoint) -> CGPoint {
        let x = (point.x - minimumX) / (maximumX - minimumX)
        return CGPoint(x: x, y: point.y)
    }

    public func normalize(_ points: [CGPoint]) -> [CGPoint] {
        points.map(normalize)
    }
}
