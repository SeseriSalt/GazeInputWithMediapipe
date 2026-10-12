//
//  CalibrationOverlayView.swift
//  IrisEyeGlance
//
//  Instructions, fixation symbol and progress for the calibration flow.
//

import UIKit
import IrisEyeGlanceCore

final class CalibrationOverlayView: UIView {
    private let instructionLabel = UILabel()
    private let stepLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let centerLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false

        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        instructionLabel.adjustsFontForContentSizeCategory = true
        instructionLabel.textColor = .label
        instructionLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        instructionLabel.layer.cornerRadius = 8
        instructionLabel.clipsToBounds = true

        stepLabel.textAlignment = .center
        stepLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        stepLabel.adjustsFontForContentSizeCategory = true
        stepLabel.textColor = .secondaryLabel

        progressView.trackTintColor = UIColor.systemGray4
        progressView.progressTintColor = InputPanelView.highlightColor

        centerLabel.textAlignment = .center
        centerLabel.font = UIFont.systemFont(ofSize: 72, weight: .bold)
        centerLabel.textColor = .systemRed
        centerLabel.accessibilityLabel = "注視点"

        let header = UIStackView(arrangedSubviews: [instructionLabel, progressView, stepLabel])
        header.axis = .vertical
        header.spacing = 6
        header.translatesAutoresizingMaskIntoConstraints = false
        centerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(header)
        addSubview(centerLabel)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor),
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            centerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func update(_ presentation: CalibrationPresentation) {
        instructionLabel.text = presentation.instruction
        instructionLabel.isHidden = presentation.instruction.isEmpty
        stepLabel.text = presentation.stepDescription
        progressView.setProgress(Float(presentation.progress), animated: true)
        centerLabel.text = presentation.centerSymbol
        isHidden = presentation.progress == 0
        if !presentation.centerSymbol.isEmpty {
            UIAccessibility.post(notification: .announcement, argument: presentation.instruction.isEmpty ? presentation.centerSymbol : presentation.instruction)
        }
    }
}
