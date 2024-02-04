//
//  SettingViewController.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/26.
//

import UIKit
import AVFoundation

public var winkSliderValue = UserDefaults.standard.object(forKey: "winkSliderValue") as? CGFloat ?? 6.2
public var winkAreaSliderValue = UserDefaults.standard.object(forKey: "winkAreaSliderValue") as? CGFloat ?? 2.8
public var glanceSliderValue = UserDefaults.standard.object(forKey: "glanceSliderValue") as? CGFloat ?? 0.9
public var integralSliderValue = UserDefaults.standard.object(forKey: "integralSliderValue") as? CGFloat ?? 5.0

class SettingViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var winkSlider: UISlider!
    @IBOutlet weak var winkLabel: UILabel!
    @IBOutlet weak var glanceSlider: UISlider!
    @IBOutlet weak var glanceLabel: UILabel!
    @IBOutlet weak var winkAreaSlider: UISlider!
    @IBOutlet weak var winkAreaLabel: UILabel!
    @IBOutlet weak var faceMoveSlider: UISlider!
    @IBOutlet weak var faceMoveLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        winkSlider.value = Float(winkSliderValue)
        winkLabel.text = String(format: "%.1f", winkSliderValue)
        
        winkAreaSlider.value = Float(winkAreaSliderValue)
        winkAreaLabel.text = String(format: "%.1f", winkAreaSliderValue)
        
        glanceSlider.value = Float(glanceSliderValue)
        glanceLabel.text = String(format: "%.1f", glanceSliderValue)
        
        faceMoveSlider.value = Float(integralSliderValue)
        faceMoveLabel.text = String(format: "%.1f", integralSliderValue)
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
        // 設定画面を閉じる際にキャプチャを再開
        let cameraVC = presentingViewController as? ViewController
        cameraVC?.restartCapture()
        // 閾値設定
        winkSliderValue = CGFloat(winkSlider.value)
        winkAreaSliderValue = CGFloat(winkAreaSlider.value)
        glanceSliderValue = CGFloat(glanceSlider.value)
        integralSliderValue = CGFloat(faceMoveSlider.value)
        UserDefaults.standard.set(winkSliderValue, forKey: "winkSliderValue")
        UserDefaults.standard.set(winkAreaSliderValue, forKey: "winkAreaSliderValue")
        UserDefaults.standard.set(glanceSliderValue, forKey: "glanceSliderValue")
        UserDefaults.standard.set(integralSliderValue, forKey: "integralSliderValue")
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
