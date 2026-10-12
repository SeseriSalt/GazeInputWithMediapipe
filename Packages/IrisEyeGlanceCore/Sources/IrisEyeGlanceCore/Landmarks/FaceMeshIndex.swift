import Foundation

/// Named indices into the 478-point MediaPipe face mesh (468 face points + 10 iris points).
/// Keeping the numbers in one place removes the magic indices that were scattered through the app.
public enum FaceMeshIndex: Int, CaseIterable, Sendable {
    case noseTip = 1
    case noseBridgeLower = 4
    case noseBridgeMid = 5
    case noseSideLeft = 45
    case noseSideRight = 275

    case leftUpperEyelid = 159
    case leftLowerEyelid = 145
    case rightUpperEyelid = 386
    case rightLowerEyelid = 374

    case leftIrisCenter = 468
    case leftIrisRim1 = 469
    case leftIrisRim2 = 470
    case leftIrisRim3 = 471
    case leftIrisRim4 = 472

    case rightIrisCenter = 473
    case rightIrisRim1 = 474
    case rightIrisRim2 = 475
    case rightIrisRim3 = 476
    case rightIrisRim4 = 477

    /// Iris center followed by the four rim points, matching the order expected by `DepthEstimator`.
    public static let leftIris: [FaceMeshIndex] = [.leftIrisCenter, .leftIrisRim1, .leftIrisRim2, .leftIrisRim3, .leftIrisRim4]
    public static let rightIris: [FaceMeshIndex] = [.rightIrisCenter, .rightIrisRim1, .rightIrisRim2, .rightIrisRim3, .rightIrisRim4]

    /// Landmarks averaged to build the x coordinate of the head reference point.
    public static let referenceX: [FaceMeshIndex] = [.noseSideLeft, .noseTip, .noseSideRight]
    /// Landmarks averaged to build the y coordinate of the head reference point.
    public static let referenceY: [FaceMeshIndex] = [.noseBridgeMid, .noseBridgeLower, .noseTip]
}
