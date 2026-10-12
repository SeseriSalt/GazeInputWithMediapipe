import Testing
@testable import IrisEyeGlanceCore

@Suite("Camera configuration")
struct CameraConfigurationTests {

    @Test("Front camera is configured for mirrored portrait BGRA frames")
    func defaults() {
        let configuration = CameraConfiguration.frontFacePortrait
        #expect(configuration.rotationAngle == 90)
        #expect(configuration.isMirrored)
        #expect(configuration.pixelFormat == CameraConfiguration.PixelFormat.bgra32)
        #expect(configuration.frameRate == 30)
    }

    @Test("Rotation angle is derived from the requested orientation")
    func rotationAngles() {
        #expect(CameraConfiguration.Orientation.portrait.rotationAngle == 90)
        #expect(CameraConfiguration.Orientation.landscapeRight.rotationAngle == 0)
        #expect(CameraConfiguration.Orientation.portraitUpsideDown.rotationAngle == 270)
        #expect(CameraConfiguration.Orientation.landscapeLeft.rotationAngle == 180)
    }
}
