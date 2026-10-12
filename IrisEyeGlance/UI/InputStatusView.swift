//
//  InputStatusView.swift
//  IrisEyeGlance
//
//  Shows the experiment question, the pending character, the last gesture and the result.
//

import UIKit
import IrisEyeGlanceCore

final class InputStatusView: UIView {
    private let questionLabel = UILabel()
    private let inputLabel = UILabel()
    private let feedbackLabel = UILabel()
    private let resultLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
        layer.cornerRadius = 10

        questionLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        questionLabel.adjustsFontForContentSizeCategory = true
        questionLabel.textAlignment = .center
        questionLabel.accessibilityLabel = "出題"

        inputLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        inputLabel.adjustsFontForContentSizeCategory = true
        inputLabel.textAlignment = .center
        inputLabel.layer.borderWidth = 0.5
        inputLabel.layer.borderColor = UIColor.separator.cgColor
        inputLabel.layer.cornerRadius = 6
        inputLabel.accessibilityLabel = "入力文字"

        feedbackLabel.font = UIFont.monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .semibold)
        feedbackLabel.adjustsFontForContentSizeCategory = true
        feedbackLabel.textAlignment = .center
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.accessibilityLabel = "最後のジェスチャ"

        resultLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        resultLabel.adjustsFontForContentSizeCategory = true
        resultLabel.textAlignment = .center
        resultLabel.textColor = .systemGreen
        resultLabel.accessibilityLabel = "正答率"

        let stack = UIStackView(arrangedSubviews: [questionLabel, inputLabel, feedbackLabel, resultLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            inputLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
        ])
        setFeedback(.idle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setQuestion(_ text: String, color: UIColor = .label) {
        questionLabel.text = text
        questionLabel.textColor = color
    }

    var pendingInput: String? {
        get { inputLabel.text }
        set { inputLabel.text = newValue }
    }

    func setInputColor(_ color: UIColor) {
        inputLabel.textColor = color
        questionLabel.textColor = color
    }

    func setFeedback(_ feedback: GestureFeedback) {
        feedbackLabel.text = feedback.symbol
        feedbackLabel.accessibilityValue = feedback.accessibilityLabel
    }

    func setResult(_ text: String) {
        resultLabel.text = text
    }
}
