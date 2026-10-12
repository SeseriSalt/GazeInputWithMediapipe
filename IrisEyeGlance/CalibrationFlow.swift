//
//  CalibrationFlow.swift
//  IrisEyeGlance
//
//  Presents the steps of `Calibrator` (instructions, center symbol, button title).
//

import UIKit
import IrisEyeGlanceCore

extension ViewController {

    private static let arrowSymbols = ["↖︎", "↗︎", "↙︎", "↘︎"]

    @MainActor
    func showCalibrationStep(_ step: Calibrator.Step) {
        switch step {
        case .idle:
            calibrationCommentLabel.text = ""
            calibrationCenterLabel.text = ""
            calibrationButton.setTitle("Calibration", for: .normal)
            inputDesignImage.center = IMAGE_INITISL_POSITION
            updateImageViewSize()

        case .restIntro:
            calibrationCommentLabel.text = "距離を30cmくらいに調整してね\nボタンを押して5秒間＋を見つめて，\n5秒くらい経ったらもう一回ボタンを押してね"
            calibrationCenterLabel.text = "＋"
            calibrationButton.setTitle("Start", for: .normal)
            // Hide the input panel while calibrating.
            inputDesignImage.center = CGPoint(x: 1000.0, y: 1000.0)
            processor.setPanelFrame(nil)

        case .restCollecting:
            calibrationCommentLabel.text = ""
            calibrationButton.setTitle("Next", for: .normal)

        case .glanceIntro:
            calibrationCommentLabel.text = "鼻を+に合わせて\n距離を30cmくらいに調整してね↓\n出てくる矢印の方向にEye Glanceしてね"
            calibrationCenterLabel.text = "＋"
            calibrationButton.setTitle("Start", for: .normal)

        case .arrow(let index):
            calibrationCommentLabel.text = ""
            calibrationCenterLabel.text = ViewController.arrowSymbols[index % ViewController.arrowSymbols.count]
            calibrationButton.setTitle("Next", for: .normal)

        case .finishing:
            calibrationCommentLabel.text = "計算中…"
            calibrationCenterLabel.text = ""

        case .done:
            calibrationCommentLabel.text = "これでバッチリ入力できます"
            calibrationCenterLabel.text = ""
            calibrationButton.setTitle("閉じる", for: .normal)
        }
    }
}
