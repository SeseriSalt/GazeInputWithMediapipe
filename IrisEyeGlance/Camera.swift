//
//  Camera.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2022/10/23.
//

import AVFoundation
import IrisEyeGlanceCore

/// Wraps the front-camera capture session.
/// Frame geometry (rotation, mirroring, pixel format) is driven by `CameraConfiguration`
/// so the values can be unit tested without AVFoundation.
class Camera: NSObject {
    let configuration: CameraConfiguration

    lazy var session: AVCaptureSession = .init()
    lazy var input: AVCaptureDeviceInput = try! AVCaptureDeviceInput(device: device)
    lazy var device: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
    lazy var output: AVCaptureVideoDataOutput = .init()

    init(configuration: CameraConfiguration = .frontFacePortrait) {
        self.configuration = configuration
        super.init()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: configuration.pixelFormat.coreVideoType]
        session.addInput(input)
        session.addOutput(output)
        applyConnectionSettings()
    }

    /// Applies rotation and mirroring using the iOS 17 `videoRotationAngle` API
    /// (`videoOrientation` is deprecated).
    private func applyConnectionSettings() {
        guard let connection = output.connection(with: .video) else { return }
        if connection.isVideoRotationAngleSupported(configuration.rotationAngle) {
            connection.videoRotationAngle = configuration.rotationAngle
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = configuration.isMirrored
        }
    }

    func setSampleBufferDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        output.setSampleBufferDelegate(delegate, queue: .main)
    }

    func start() {
        session.startRunning()
    }

    func stop() {
        session.stopRunning()
    }
}

extension CameraConfiguration.PixelFormat {
    /// Core Video pixel format constant for this configuration value.
    var coreVideoType: OSType {
        switch self {
        case .bgra32: return kCVPixelFormatType_32BGRA
        }
    }
}
