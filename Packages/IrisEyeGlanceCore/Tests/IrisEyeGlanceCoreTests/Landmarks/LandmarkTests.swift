import Foundation
import Testing
@testable import IrisEyeGlanceCore

@Suite("Face mesh indices")
struct FaceMeshIndexTests {

    @Test("Indices match the MediaPipe face mesh numbers used by the original implementation")
    func rawValues() {
        #expect(FaceMeshIndex.noseTip.rawValue == 1)
        #expect(FaceMeshIndex.leftIrisCenter.rawValue == 468)
        #expect(FaceMeshIndex.rightIrisCenter.rawValue == 473)
        #expect(FaceMeshIndex.leftUpperEyelid.rawValue == 159)
        #expect(FaceMeshIndex.leftLowerEyelid.rawValue == 145)
        #expect(FaceMeshIndex.rightUpperEyelid.rawValue == 386)
        #expect(FaceMeshIndex.rightLowerEyelid.rawValue == 374)
    }

    @Test("Iris groups contain the center followed by four rim points")
    func irisGroups() {
        #expect(FaceMeshIndex.leftIris.map(\.rawValue) == [468, 469, 470, 471, 472])
        #expect(FaceMeshIndex.rightIris.map(\.rawValue) == [473, 474, 475, 476, 477])
    }

    @Test("Reference point uses nose-bridge landmarks for x and y separately")
    func referencePoint() {
        #expect(FaceMeshIndex.referenceX.map(\.rawValue) == [45, 1, 275])
        #expect(FaceMeshIndex.referenceY.map(\.rawValue) == [5, 4, 1])
    }
}

@Suite("Landmark normalizer")
struct LandmarkNormalizerTests {

    @Test("x is rescaled with the calibrated range, y is untouched")
    func normalize() {
        let normalizer = LandmarkNormalizer()
        let point = normalizer.normalize(CGPoint(x: 0.08978804, y: 0.42))
        #expect(abs(point.x) < 1e-9)
        #expect(point.y == 0.42)

        let max = normalizer.normalize(CGPoint(x: 0.9095595, y: 0.1))
        #expect(abs(max.x - 1.0) < 1e-9)
    }

    @Test("FaceFrame exposes landmarks by index")
    func faceFrame() {
        var landmarks = Array(repeating: CGPoint.zero, count: FaceFrame.landmarkCount)
        landmarks[FaceMeshIndex.noseTip.rawValue] = CGPoint(x: 0.5, y: 0.6)
        let frame = FaceFrame(index: 3, landmarks: landmarks)
        #expect(frame[.noseTip] == CGPoint(x: 0.5, y: 0.6))
        #expect(frame.index == 3)
        #expect(FaceFrame.landmarkCount == 478)
    }
}
