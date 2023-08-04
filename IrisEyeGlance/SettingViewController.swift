//
//  SettingViewController.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/26.
//

import UIKit
import AVFoundation

public var winkSliderValue: CGFloat = 8.2
public var glanceSliderValue: CGFloat = 1.1
public var faceMoveSliderValue: CGFloat = 50.0

class SettingViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var winkSlider: UISlider!
    @IBOutlet weak var winkLabel: UILabel!
    @IBOutlet weak var glanceSlider: UISlider!
    @IBOutlet weak var glanceLabel: UILabel!
    @IBOutlet weak var faceMoveSlider: UISlider!
    @IBOutlet weak var faceMoveLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        winkSlider.value = Float(winkSliderValue)
        winkLabel.text = String(format: "%.1f", winkSliderValue)
        
        glanceSlider.value = Float(glanceSliderValue)
        glanceLabel.text = String(format: "%.1f", glanceSliderValue)
        
        faceMoveSlider.value = Float(faceMoveSliderValue)
        faceMoveLabel.text = String(round(faceMoveSliderValue))
    }
    
    @IBAction func winkSliderAction(_ sender: UISlider) {
        sliderDidChangeValue(sender, label: winkLabel)
    }
    
    @IBAction func glanceSliderAction(_ sender: UISlider) {
        sliderDidChangeValue(sender, label: glanceLabel)
    }
    
    @IBAction func faceMoveSliderAction(_ sender: UISlider) {
        sliderDidChangeValueInt(sender, label: faceMoveLabel)
    }
    
    
    @IBAction func exit(_ sender: Any) {
        // 設定画面を閉じる際にキャプチャを再開
        let cameraVC = presentingViewController as? ViewController
        cameraVC?.restartCapture()
        // 閾値設定
        winkSliderValue = CGFloat(winkSlider.value)
        glanceSliderValue = CGFloat(glanceSlider.value)
        faceMoveSliderValue = CGFloat(faceMoveSlider.value)
        // 画面を閉じる
        dismiss(animated: true)
    }
    
    @objc func sliderDidChangeValue(_ sender: UISlider, label: UILabel) {
        let roundValue = roundf(sender.value * 10) / 10
            
            // set round value
            sender.value = roundValue
            label.text = String(roundValue)
        }
    
    @objc func sliderDidChangeValueInt(_ sender: UISlider, label: UILabel) {
        let roundValue = round(sender.value)
            
            // set round value
            sender.value = roundValue
            label.text = String(roundValue)
        }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
