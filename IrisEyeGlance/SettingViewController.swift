//
//  SettingViewController.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/26.
//

import UIKit
import AVFoundation

public var glanceUpSliderValue: CGFloat = -1.0
public var glanceDownSliderValue: CGFloat = 1.0

class SettingViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var glanceUpSlider: UISlider!
    @IBOutlet weak var glanceUpSliderLabel: UILabel!
    @IBOutlet weak var glanceDownSlider: UISlider!
    @IBOutlet weak var glanceDownSliderLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        glanceUpSlider.value = Float(-glanceUpSliderValue)
        glanceUpSliderLabel.text = String(format: "%.1f", -glanceUpSliderValue)
        
        glanceDownSlider.value = Float(glanceDownSliderValue)
        glanceDownSliderLabel.text = String(format: "%.1f", glanceDownSliderValue)

        // Do any additional setup after loading the view.
    }
    
    @IBAction func glanceUpSliderAction(_ sender: UISlider) {
        sliderDidChangeValue(sender, label: glanceUpSliderLabel)
    }
    
    @IBAction func GlanceDownSliderAction(_ sender: UISlider) {
        sliderDidChangeValue(sender, label: glanceDownSliderLabel)
    }
    
    
    @IBAction func exit(_ sender: Any) {
        // 設定画面を閉じる際にキャプチャを再開
        let cameraVC = presentingViewController as? ViewController
        cameraVC?.restartCapture()
        // 閾値設定
        glanceUpSliderValue = CGFloat(-glanceUpSlider.value)
        glanceDownSliderValue = CGFloat(glanceDownSlider.value)
        // 画面を閉じる
        dismiss(animated: true)
    }
    
    @objc func sliderDidChangeValue(_ sender: UISlider, label: UILabel) {
        let roundValue = roundf(sender.value * 10) / 10
            
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
