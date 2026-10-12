import Foundation

/// Pure description of how the capture session should be configured.
/// Kept free of AVFoundation so it can be unit tested on any platform.
public struct CameraConfiguration: Equatable, Sendable {

    public enum Orientation: Sendable {
        case portrait
        case portraitUpsideDown
        case landscapeLeft
        case landscapeRight

        /// Rotation angle in degrees for `AVCaptureConnection.videoRotationAngle`.
        public var rotationAngle: Double {
            switch self {
            case .portrait: return 90
            case .portraitUpsideDown: return 270
            case .landscapeLeft: return 180
            case .landscapeRight: return 0
            }
        }
    }

    public enum PixelFormat: Sendable {
        /// `kCVPixelFormatType_32BGRA`, the format expected by the SYIris tracker.
        case bgra32
    }

    public var orientation: Orientation
    public var isMirrored: Bool
    public var pixelFormat: PixelFormat
    public var frameRate: Int

    public init(orientation: Orientation, isMirrored: Bool, pixelFormat: PixelFormat, frameRate: Int) {
        self.orientation = orientation
        self.isMirrored = isMirrored
        self.pixelFormat = pixelFormat
        self.frameRate = frameRate
    }

    public var rotationAngle: Double { orientation.rotationAngle }

    /// Front camera, portrait, mirrored like a selfie preview, 30 fps.
    public static let frontFacePortrait = CameraConfiguration(
        orientation: .portrait,
        isMirrored: true,
        pixelFormat: .bgra32,
        frameRate: 30
    )
}
