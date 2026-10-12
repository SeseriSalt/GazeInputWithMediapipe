//
//  SettingViewController.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/26.
//

import UIKit
import IrisEyeGlanceCore

class SettingViewController: UIViewController {

    @IBOutlet weak var winkSlider: UISlider!
    @IBOutlet weak var winkLabel: UILabel!
    @IBOutlet weak var glanceSlider: UISlider!
    @IBOutlet weak var glanceLabel: UILabel!
    @IBOutlet weak var winkAreaSlider: UISlider!
    @IBOutlet weak var winkAreaLabel: UILabel!
    @IBOutlet weak var faceMoveSlider: UISlider!
    @IBOutlet weak var faceMoveLabel: UILabel!

    private var parameters = DetectionParameters(userDefaults: .standard)

    override func viewDidLoad() {
        super.viewDidLoad()
        show(parameters)
    }

    private func show(_ parameters: DetectionParameters) {
        winkSlider.value = Float(parameters.winkThreshold)
        winkLabel.text = String(format: "%.1f", parameters.winkThreshold)

        winkAreaSlider.value = Float(parameters.winkAreaMultiplier)
        winkAreaLabel.text = String(format: "%.1f", parameters.winkAreaMultiplier)

        glanceSlider.value = Float(parameters.glanceThreshold)
        glanceLabel.text = String(format: "%.1f", parameters.glanceThreshold)

        faceMoveSlider.value = Float(parameters.glanceIntegralMultiplier)
        faceMoveLabel.text = String(format: "%.1f", parameters.glanceIntegralMultiplier)
    }

    @IBAction func winkSliderAction(_ sender: UISlider) {
        sliderDidChangeValue(sender, label: winkLabel)
    }

    @IBAction func winkAreaSliderAction(_ sender: UISlider) {
        sliderDidChangeValue(sender, label: winkAreaLabel)
    }

    @IBAction func glanceSliderAction(_ sender: UISlider) {
        sliderDidChangeValue(sender, label: glanceLabel)
    }

    @IBAction func faceMoveSliderAction(_ sender: UISlider) {
        sliderDidChangeValue(sender, label: faceMoveLabel)
    }

    @IBAction func exit(_ sender: Any) {
        parameters.winkThreshold = Double(winkSlider.value)
        parameters.winkAreaMultiplier = Double(winkAreaSlider.value)
        parameters.glanceThreshold = Double(glanceSlider.value)
        parameters.glanceIntegralMultiplier = Double(faceMoveSlider.value)
        parameters.save(to: .standard)

        let cameraVC = presentingViewController as? ViewController
        cameraVC?.restartCapture(with: parameters)
        dismiss(animated: true)
    }

    @objc func sliderDidChangeValue(_ sender: UISlider, label: UILabel) {
        let roundValue = roundf(sender.value * 10) / 10
        sender.value = roundValue
        label.text = String(format: "%.1f", roundValue)
    }
}
