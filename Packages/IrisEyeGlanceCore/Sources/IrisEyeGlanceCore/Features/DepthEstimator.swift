import CoreGraphics
import Foundation

/// Estimates the distance between the camera and the eye from the apparent iris diameter,
/// using a pinhole camera model and the average human iris diameter.
public struct DepthEstimator: Sendable {
    /// Average horizontal iris diameter in millimetres.
    public static let irisDiameterMM: Double = 11.8

    public var focalLength: Double
    public var imageWidth: Double
    public var imageHeight: Double

    public init(focalLength: Double, imageWidth: Double, imageHeight: Double) {
        self.focalLength = focalLength
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }

    /// Pixel distance between two normalized landmarks.
    public func pixelDistance(_ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = (a.x - b.x) * imageWidth
        let dy = (a.y - b.y) * imageHeight
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Iris diameter in pixels from the five iris landmarks (center, then four rim points).
    public func irisDiameter(_ iris: [CGPoint]) -> Double {
        precondition(iris.count >= 5, "Expected iris center and four rim points")
        let vertical = pixelDistance(iris[2], iris[4])
        let horizontal = pixelDistance(iris[1], iris[3])
        return (vertical + horizontal) / 2
    }

    /// Distance from the camera in millimetres.
    public func depth(irisCenter: CGPoint, irisDiameter: Double) -> Double {
        let center = CGPoint(x: 0.5, y: 0.5)
        let offset = pixelDistance(center, irisCenter)
        let ray = (focalLength * focalLength + offset * offset).squareRoot()
        return DepthEstimator.irisDiameterMM * ray / irisDiameter
    }
}
