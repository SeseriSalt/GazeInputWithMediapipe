import CoreGraphics
import Foundation

/// Keeps a three-frame history of one iris center and the head reference point so that
/// two-frame differences can be computed. Replaces the former `EyeData` class.
public struct IrisSignal: Sendable {
    private var iris = CGPoint.zero
    private var irisPrevious = CGPoint.zero
    private var irisPrevious2 = CGPoint.zero
    private var reference = CGPoint.zero
    private var referencePrevious = CGPoint.zero
    private var referencePrevious2 = CGPoint.zero

    public init() {}

    public mutating func update(irisCenter: CGPoint, referencePoint: CGPoint) {
        irisPrevious2 = irisPrevious
        irisPrevious = iris
        iris = irisCenter
        referencePrevious2 = referencePrevious
        referencePrevious = reference
        reference = referencePoint
    }

    /// Iris movement over the last two frames.
    public var irisDelta2: CGPoint {
        CGPoint(x: iris.x - irisPrevious2.x, y: iris.y - irisPrevious2.y)
    }

    /// Reference point movement over the last two frames.
    public var referenceDelta2: CGPoint {
        CGPoint(x: reference.x - referencePrevious2.x, y: reference.y - referencePrevious2.y)
    }

    /// Iris movement with the head movement removed.
    public var irisMinusReferenceDelta2: CGPoint {
        let iris = irisDelta2
        let reference = referenceDelta2
        return CGPoint(x: iris.x - reference.x, y: iris.y - reference.y)
    }

    public mutating func reset() {
        self = IrisSignal()
    }
}
