//
//  MainViewController.swift
//  IrisEyeGlance
//
//  The single input screen. Owns the camera, the tracker bridge and the frame processor,
//  renders processor updates and forwards user actions. Built in code with Auto Layout.
//

import AVFoundation
import UIKit
import IrisEyeGlanceCore

final class MainViewController: UIViewController {

    // MARK: Model

    private let camera = Camera()
    private let processor = FrameProcessor(parameters: DetectionParameters(userDefaults: .standard),
                                           screenSize: CGSize(width: 390, height: 844))
    private var trackerBridge: TrackerBridge?
    private var experiment = ExperimentSession(questionSet: ExperimentSession.QuestionSet(layout: KeyboardLayout.preferred(from: .standard)))
    private var isRecording = false
    private var lastEventFrame = 0
    private var hasPlacedPanel = false
    private var lastHapticTime: TimeInterval = 0
    private static let feedbackFrames = 4
    /// Minimum interval between selection haptics so cursor jitter on a grid line does not buzz.
    private static let hapticInterval: TimeInterval = 0.12

    // MARK: Views

    private let previewView = CameraPreviewView()
    private let cursorView = CursorOverlayView()
    private let panelView = InputPanelView()
    private let statusView = InputStatusView()
    private let debugView = DebugOverlayView()
    private let calibrationView = CalibrationOverlayView()
    private let toolbar = UIStackView()

    private lazy var resetButton = makeButton(title: "Reset", symbol: "arrow.counterclockwise", action: #selector(resetTapped))
    private lazy var recordButton = makeButton(title: "Record", symbol: "record.circle", action: #selector(recordTapped))
    private lazy var calibrationButton = makeButton(title: "Calibration", symbol: "scope", action: #selector(calibrationTapped))
    private lazy var settingsButton = makeButton(title: "Settings", symbol: "slider.horizontal.3", action: #selector(settingsTapped))
    private lazy var debugButton = makeButton(title: "Debug", symbol: "ladybug", action: #selector(debugTapped))

    private let feedbackGenerator = UISelectionFeedbackGenerator()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildHierarchy()
        buildToolbar()
        installGestures()

        let layout = KeyboardLayout.preferred(from: .standard)
        panelView.layout = layout
        processor.setLayout(layout)
        statusView.setQuestion(experiment.currentQuestion)
        statusView.pendingInput = ""
        statusView.setResult("")
        debugView.isHidden = true
        calibrationView.update(CalibrationPresentation(step: .idle))
        feedbackGenerator.prepare()

        processor.onUpdate = { [weak self] update in
            self?.apply(update)
        }

        startCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        processor.setScreenSize(view.bounds.size)
        if !hasPlacedPanel, view.bounds.width > 0 {
            hasPlacedPanel = true
            panelView.bounds.size = panelView.preset.size
            panelView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            pushPanelFrame()
        }
    }

    // MARK: Hierarchy

    private func buildHierarchy() {
        [previewView, panelView, cursorView, statusView, calibrationView, debugView, toolbar].forEach(view.addSubview)
        [previewView, cursorView, statusView, calibrationView, debugView, toolbar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        // The panel is positioned by dragging, so it keeps a frame-based layout.
        panelView.translatesAutoresizingMaskIntoConstraints = true

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            cursorView.topAnchor.constraint(equalTo: view.topAnchor),
            cursorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cursorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cursorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            statusView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 8),
            statusView.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            statusView.widthAnchor.constraint(lessThanOrEqualTo: safe.widthAnchor, constant: -32),

            calibrationView.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 8),
            calibrationView.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: -8),
            calibrationView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            calibrationView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),

            debugView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 8),
            debugView.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: -8),
            debugView.widthAnchor.constraint(lessThanOrEqualTo: safe.widthAnchor, constant: -16),

            toolbar.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 8),
            toolbar.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -8),
            toolbar.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -8),
        ])
    }

    private func buildToolbar() {
        toolbar.axis = .horizontal
        toolbar.distribution = .fillEqually
        toolbar.spacing = 6
        [resetButton, recordButton, calibrationButton, settingsButton, debugButton].forEach(toolbar.addArrangedSubview)
    }

    private func makeButton(title: String, symbol: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1),
        ]))
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePlacement = .top
        configuration.imagePadding = 2
        configuration.baseBackgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        configuration.baseForegroundColor = .label
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = title
        return button
    }

    private func installGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panelView.addGestureRecognizer(pan)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        panelView.addGestureRecognizer(doubleTap)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        view.addGestureRecognizer(longPress)
    }

    // MARK: Camera

    private func startCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startCamera()
                    } else {
                        self.presentCameraDeniedAlert()
                    }
                }
            }
            return
        case .denied, .restricted:
            presentCameraDeniedAlert()
            return
        @unknown default:
            break
        }
        if let error = camera.configurationError {
            presentAlert(title: "カメラを使用できません", message: String(describing: error))
            return
        }
        if trackerBridge == nil {
            trackerBridge = TrackerBridge(processor: processor)
        }
        guard let trackerBridge else {
            presentAlert(title: "トラッカーを初期化できません", message: "SYIris.framework の読み込みに失敗しました。")
            return
        }
        camera.setSampleBufferDelegate(trackerBridge)
        previewView.session = camera.session
        camera.start()
    }

    /// Called by the scene delegate when the app goes to the background.
    func pauseCapture() {
        camera.stop()
    }

    /// Called by the scene delegate when the app returns to the foreground.
    func resumeCapture() {
        camera.start()
    }

    // MARK: Rendering one frame

    @MainActor
    private func apply(_ update: FrameProcessor.Update) {
        cursorView.update(point: update.cursorPoint)
        if update.regionChanged {
            let now = CACurrentMediaTime()
            if now - lastHapticTime > MainViewController.hapticInterval {
                lastHapticTime = now
                feedbackGenerator.selectionChanged()
                feedbackGenerator.prepare()
            }
        }
        panelView.setHighlightedRegion(update.region)
        panelView.layout = update.layout

        let features = update.result.features
        if let event = update.result.event {
            lastEventFrame = features.frame
            statusView.setFeedback(GestureFeedback(event: event))
            if case .wink(let eye) = event {
                statusView.setInputColor(eye == .left ? .systemRed : .systemBlue)
            }
        } else if features.frame - lastEventFrame > MainViewController.feedbackFrames {
            statusView.setFeedback(.idle)
        }

        handle(update.action)

        if !debugView.isHidden {
            debugView.update(DebugSnapshot(result: update.result, cameraFrames: update.cameraFrames, region: update.region))
        }

        if update.calibrationResult != nil {
            showCalibrationStep(update.calibrationStep)
        }
    }

    @MainActor
    private func handle(_ action: InputAction) {
        switch action {
        case .none:
            break
        case .insert(let character):
            statusView.pendingInput = character
            experiment.recordAttempt()
            if let outcome = experiment.check(character) {
                showExperimentOutcome(outcome)
            }
        case .switchLayout(let layout):
            applyLayout(layout)
        case .toggleCase(let upper):
            statusView.pendingInput = upper ? statusView.pendingInput?.uppercased() : statusView.pendingInput?.lowercased()
        }
    }

    /// Switches the panel, persists the choice and restarts the experiment with the
    /// question set that can be typed on that panel.
    private func applyLayout(_ layout: KeyboardLayout) {
        panelView.layout = layout
        layout.savePreference(to: .standard)
        let questionSet = ExperimentSession.QuestionSet(layout: layout)
        guard experiment.questionSet != questionSet else { return }
        experiment = ExperimentSession(questionSet: questionSet)
        statusView.setQuestion(experiment.currentQuestion)
        statusView.pendingInput = ""
        statusView.setResult("")
        statusView.setInputColor(.label)
    }

    private func showExperimentOutcome(_ outcome: ExperimentSession.Outcome) {
        statusView.pendingInput = ""
        switch outcome {
        case .advanced(let next):
            statusView.setQuestion(next)
        case .finished(let accuracy):
            statusView.setQuestion("終わり。", color: .systemGreen)
            statusView.setResult(String(format: "%.1f%%", accuracy * 100))
        }
    }

    // MARK: Panel geometry

    private func pushPanelFrame() {
        let hidden = CalibrationPresentation(step: processor.calibrationStep).hidesInputPanel
        processor.setPanelFrame(hidden ? nil : panelView.panelFrame)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        panelView.center = CGPoint(x: panelView.center.x + translation.x, y: panelView.center.y + translation.y)
        gesture.setTranslation(.zero, in: view)
        pushPanelFrame()
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let center = panelView.center
        panelView.preset = panelView.preset.next
        panelView.bounds.size = panelView.preset.size
        panelView.center = center
        pushPanelFrame()
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        toggleDebug()
    }

    // MARK: Toolbar actions

    @objc private func resetTapped() {
        experiment.reset()
        statusView.setQuestion(experiment.currentQuestion)
        statusView.pendingInput = ""
        statusView.setResult("")
        statusView.setInputColor(.label)
        statusView.setFeedback(.idle)
        lastEventFrame = 0
        trackerBridge?.resetFrameCount()
        processor.reset()
    }

    @objc private func recordTapped() {
        if isRecording {
            processor.stopRecording()
            isRecording = false
        } else {
            let url = documentsDirectory.appendingPathComponent("\(timestamp()).csv", isDirectory: false)
            do {
                try processor.startRecording(to: url)
                isRecording = true
            } catch {
                presentAlert(title: "記録を開始できません", message: String(describing: error))
                return
            }
        }
        var configuration = recordButton.configuration
        configuration?.attributedTitle = AttributedString(isRecording ? "Stop" : "Record", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1),
        ]))
        configuration?.image = UIImage(systemName: isRecording ? "stop.circle.fill" : "record.circle")
        configuration?.baseForegroundColor = isRecording ? .systemRed : .label
        recordButton.configuration = configuration
        recordButton.accessibilityLabel = isRecording ? "記録を停止" : "記録を開始"
    }

    @objc private func calibrationTapped() {
        let step = processor.advanceCalibration()
        showCalibrationStep(step)
    }

    @objc private func settingsTapped() {
        // The camera keeps running: stopping it only produced capture-session restarts.
        let settings = SettingsViewController(parameters: processor.parameters, layout: panelView.layout) { [weak self] parameters, layout in
            guard let self else { return }
            processor.setParameters(parameters)
            processor.reset()
            if layout != panelView.layout {
                processor.setLayout(layout)
                applyLayout(layout)
            }
        }
        let navigation = UINavigationController(rootViewController: settings)
        navigation.modalPresentationStyle = .formSheet
        present(navigation, animated: true)
    }

    @objc private func debugTapped() {
        toggleDebug()
    }

    private func toggleDebug() {
        debugView.isHidden.toggle()
    }

    // MARK: Calibration

    private func showCalibrationStep(_ step: Calibrator.Step) {
        let presentation = CalibrationPresentation(step: step)
        calibrationView.update(presentation)
        panelView.isHidden = presentation.hidesInputPanel
        var configuration = calibrationButton.configuration
        configuration?.attributedTitle = AttributedString(presentation.buttonTitle, attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1),
        ]))
        calibrationButton.configuration = configuration
        calibrationButton.accessibilityLabel = presentation.buttonTitle
        pushPanelFrame()
    }

    // MARK: Helpers

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }

    private func presentCameraDeniedAlert() {
        let alert = UIAlertController(title: "カメラへのアクセスが必要です",
                                      message: "視線とまばたきで入力するため、設定アプリでカメラを許可してください。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "設定を開く", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "閉じる", style: .cancel))
        present(alert, animated: true)
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
