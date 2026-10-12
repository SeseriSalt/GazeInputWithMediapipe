import CoreGraphics
import Foundation

/// One frame of face landmarks in normalized image coordinates (0...1), as produced by the tracker.
public struct FaceFrame: Sendable {
    public static let landmarkCount = 478

    /// Monotonically increasing frame counter.
    public let index: Int
    public let landmarks: [CGPoint]

    public init(index: Int, landmarks: [CGPoint]) {
        self.index = index
        self.landmarks = landmarks
    }

    public subscript(_ index: FaceMeshIndex) -> CGPoint {
        landmarks[index.rawValue]
    }

    public func points(_ indices: [FaceMeshIndex]) -> [CGPoint] {
        indices.map { landmarks[$0.rawValue] }
    }

    /// True when the tracker delivered the full mesh including iris points.
    public var isComplete: Bool {
        landmarks.count >= FaceFrame.landmarkCount
    }
}
