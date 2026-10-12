//
//  SettingsViewController.swift
//  IrisEyeGlance
//
//  Manual tuning of the detection thresholds. Built with a stack view so it adapts
//  to any screen size and Dynamic Type setting.
//

import UIKit
import IrisEyeGlanceCore

final class SettingsViewController: UIViewController {

    private struct SliderSpec {
        let title: String
        let detail: String
        let range: ClosedRange<Float>
        let keyPath: WritableKeyPath<DetectionParameters, Double>
    }

    private static let specs: [SliderSpec] = [
        SliderSpec(title: "Wink / Blink 波形しきい値",
                   detail: "瞼の高さ差分がこの値を超えるとウィンク候補になります",
                   range: 5...8, keyPath: \.winkThreshold),
        SliderSpec(title: "Wink 積分値倍率",
                   detail: "ウィンク波形の面積しきい値 = 波形しきい値 × 倍率",
                   range: 2...5, keyPath: \.winkAreaMultiplier),
        SliderSpec(title: "Eye Glance 波形しきい値",
                   detail: "自動キャリブレーションで更新されます",
                   range: 0...2, keyPath: \.glanceThreshold),
        SliderSpec(title: "Eye Glance 積分値倍率",
                   detail: "自動キャリブレーションで更新されます",
                   range: 0...10, keyPath: \.glanceIntegralMultiplier),
    ]

    private var parameters: DetectionParameters
    private var layout: KeyboardLayout
    private let onClose: (DetectionParameters, KeyboardLayout) -> Void
    private var sliders: [UISlider] = []
    private var valueLabels: [UILabel] = []
    private let layoutControl = UISegmentedControl(items: ["日本語", "英語"])

    init(parameters: DetectionParameters, layout: KeyboardLayout, onClose: @escaping (DetectionParameters, KeyboardLayout) -> Void) {
        self.parameters = parameters
        self.layout = layout
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
        title = "設定"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "閉じる", style: .done, target: self, action: #selector(closeTapped))

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        stack.addArrangedSubview(makeLayoutRow())

        for (index, spec) in SettingsViewController.specs.enumerated() {
            stack.addArrangedSubview(makeRow(index: index, spec: spec))
        }

        var resetConfiguration = UIButton.Configuration.tinted()
        resetConfiguration.title = "既定値に戻す"
        let resetButton = UIButton(configuration: resetConfiguration)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        stack.addArrangedSubview(resetButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])
        showValues()
    }

    /// Input mode: the panel layout and the experiment question set follow it.
    private func makeLayoutRow() -> UIView {
        let title = UILabel()
        title.text = "入力モード"
        title.font = UIFont.preferredFont(forTextStyle: .headline)
        title.adjustsFontForContentSizeCategory = true

        let detail = UILabel()
        detail.text = "パネルの文字と出題される文字が切り替わります。入力中は 🌐 キーでも切り替えられます"
        detail.numberOfLines = 0
        detail.font = UIFont.preferredFont(forTextStyle: .footnote)
        detail.adjustsFontForContentSizeCategory = true
        detail.textColor = .secondaryLabel

        layoutControl.selectedSegmentIndex = layout.isAlphabet ? 1 : 0
        layoutControl.addTarget(self, action: #selector(layoutChanged(_:)), for: .valueChanged)
        layoutControl.accessibilityLabel = "入力モード"

        let row = UIStackView(arrangedSubviews: [title, detail, layoutControl])
        row.axis = .vertical
        row.spacing = 6
        return row
    }

    @objc private func layoutChanged(_ sender: UISegmentedControl) {
        layout = sender.selectedSegmentIndex == 1 ? .alphabetLower : .japanese
    }

    private func makeRow(index: Int, spec: SliderSpec) -> UIView {
        let title = UILabel()
        title.text = spec.title
        title.font = UIFont.preferredFont(forTextStyle: .headline)
        title.adjustsFontForContentSizeCategory = true

        let detail = UILabel()
        detail.text = spec.detail
        detail.numberOfLines = 0
        detail.font = UIFont.preferredFont(forTextStyle: .footnote)
        detail.adjustsFontForContentSizeCategory = true
        detail.textColor = .secondaryLabel

        let slider = UISlider()
        slider.minimumValue = spec.range.lowerBound
        slider.maximumValue = spec.range.upperBound
        slider.tag = index
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        slider.accessibilityLabel = spec.title
        sliders.append(slider)

        let minimum = UILabel()
        minimum.text = String(format: "%.1f", spec.range.lowerBound)
        minimum.font = UIFont.preferredFont(forTextStyle: .caption1)
        minimum.textColor = .secondaryLabel

        let maximum = UILabel()
        maximum.text = String(format: "%.1f", spec.range.upperBound)
        maximum.font = UIFont.preferredFont(forTextStyle: .caption1)
        maximum.textColor = .secondaryLabel

        let value = UILabel()
        value.font = UIFont.monospacedDigitSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .semibold)
        value.textAlignment = .right
        value.setContentHuggingPriority(.required, for: .horizontal)
        valueLabels.append(value)

        let header = UIStackView(arrangedSubviews: [title, value])
        header.axis = .horizontal
        header.spacing = 8

        let sliderRow = UIStackView(arrangedSubviews: [minimum, slider, maximum])
        sliderRow.axis = .horizontal
        sliderRow.spacing = 8
        sliderRow.alignment = .center

        let row = UIStackView(arrangedSubviews: [header, detail, sliderRow])
        row.axis = .vertical
        row.spacing = 6
        return row
    }

    private func showValues() {
        for (index, spec) in SettingsViewController.specs.enumerated() {
            let value = parameters[keyPath: spec.keyPath]
            sliders[index].value = Float(value)
            valueLabels[index].text = String(format: "%.1f", value)
        }
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        let rounded = Double((sender.value * 10).rounded() / 10)
        sender.value = Float(rounded)
        let spec = SettingsViewController.specs[sender.tag]
        parameters[keyPath: spec.keyPath] = rounded
        valueLabels[sender.tag].text = String(format: "%.1f", rounded)
    }

    @objc private func resetTapped() {
        parameters = DetectionParameters()
        showValues()
    }

    @objc private func closeTapped() {
        parameters.save(to: .standard)
        layout.savePreference(to: .standard)
        onClose(parameters, layout)
        dismiss(animated: true)
    }
}
