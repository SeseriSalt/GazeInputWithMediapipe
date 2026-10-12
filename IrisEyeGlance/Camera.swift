//
//  Camera.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2022/10/23.
//

import AVFoundation
import IrisEyeGlanceCore

/// Wraps the front-camera capture session.
///
/// Frames are delivered on a dedicated queue so that tracking never runs on the main thread.
/// Frame geometry (rotation, mirroring, pixel format) is driven by `CameraConfiguration`.
final class Camera: NSObject, @unchecked Sendable {
    let configuration: CameraConfiguration
    let session = AVCaptureSession()

    /// Error raised while configuring inputs and outputs, nil when the camera is ready.
    private(set) var configurationError: Error?

    private let sessionQueue = DispatchQueue(label: "jp.lab413.IrisEyeGlance.Camera.session")
    private let videoQueue = DispatchQueue(label: "jp.lab413.IrisEyeGlance.Camera.video", qos: .userInteractive)
    private let output = AVCaptureVideoDataOutput()

    enum CameraError: Error {
        case frontCameraUnavailable
        case cannotAddInput
        case cannotAddOutput
    }

    init(configuration: CameraConfiguration = .frontFacePortrait) {
        self.configuration = configuration
        super.init()
        do {
            try configure()
        } catch {
            configurationError = error
        }
    }

    private func configure() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw CameraError.frontCameraUnavailable
        }
        let input = try AVCaptureDeviceInput(device: device)

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard session.canAddInput(input) else { throw CameraError.cannotAddInput }
        session.addInput(input)

        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: configuration.pixelFormat.coreVideoType]
        output.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(output) else { throw CameraError.cannotAddOutput }
        session.addOutput(output)

        applyConnectionSettings()
    }

    /// Applies rotation and mirroring using the iOS 17 `videoRotationAngle` API.
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
        output.setSampleBufferDelegate(delegate, queue: videoQueue)
    }

    func start() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
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
