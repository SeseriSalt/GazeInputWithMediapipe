//
//  Experiment.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/05/30.
//

import UIKit
import IrisEyeGlanceCore

extension ViewController {

    @MainActor
    func showExperimentOutcome(_ outcome: ExperimentSession.Outcome) {
        inputLabel.text = ""
        switch outcome {
        case .advanced(let next):
            questionLabel.text = next
        case .finished(let accuracy):
            questionLabel.text = "終わり。"
            questionLabel.textColor = .green
            resultLabel.text = String(format: "%.1f", accuracy * 100) + "%"
        }
    }

    @MainActor
    func resetExperiment() {
        experiment.reset()
        inputLabel.text = ""
        questionLabel.text = experiment.currentQuestion
        questionLabel.textColor = .black
        resultLabel.text = ""
    }
}
