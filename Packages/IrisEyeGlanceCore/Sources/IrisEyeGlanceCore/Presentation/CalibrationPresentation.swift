import Foundation

/// Text and progress shown for each `Calibrator.Step`.
public struct CalibrationPresentation: Sendable, Equatable {
    public let instruction: String
    public let centerSymbol: String
    public let buttonTitle: String
    public let stepDescription: String
    /// 0 when idle, 1 when done.
    public let progress: Double
    public let hidesInputPanel: Bool

    private static let totalSteps = 12.0

    public init(step: Calibrator.Step) {
        switch step {
        case .idle:
            instruction = ""
            centerSymbol = ""
            buttonTitle = "Calibration"
            stepDescription = ""
            progress = 0
            hidesInputPanel = false
        case .restIntro:
            instruction = "距離を30cmくらいに調整してください。\nボタンを押したら5秒間 ＋ を見つめ、\nもう一度ボタンを押してください。"
            centerSymbol = "＋"
            buttonTitle = "Start"
            stepDescription = "準備"
            progress = 1 / CalibrationPresentation.totalSteps
            hidesInputPanel = true
        case .restCollecting:
            instruction = "＋ を見つめたままにしてください"
            centerSymbol = "＋"
            buttonTitle = "Next"
            stepDescription = "静止中"
            progress = 2 / CalibrationPresentation.totalSteps
            hidesInputPanel = true
        case .glanceIntro:
            instruction = "鼻を ＋ に合わせ、距離を30cmくらいに保ってください。\n表示される矢印の方向に Eye Glance してください。"
            centerSymbol = "＋"
            buttonTitle = "Start"
            stepDescription = "準備"
            progress = 3 / CalibrationPresentation.totalSteps
            hidesInputPanel = true
        case .arrow(let index):
            instruction = "矢印の方向を一瞥してください"
            centerSymbol = GlanceDirection.allCases[index % GlanceDirection.allCases.count].arrow
            buttonTitle = "Next"
            stepDescription = "\(index + 1) / \(Calibrator.arrowCount)"
            progress = (4 + Double(index)) / CalibrationPresentation.totalSteps
            hidesInputPanel = true
        case .finishing:
            instruction = "計算中…"
            centerSymbol = ""
            buttonTitle = "Next"
            stepDescription = "計算中"
            progress = 11.5 / CalibrationPresentation.totalSteps
            hidesInputPanel = true
        case .done:
            instruction = "これでバッチリ入力できます"
            centerSymbol = ""
            buttonTitle = "閉じる"
            stepDescription = "完了"
            progress = 1
            hidesInputPanel = true
        }
    }
}
