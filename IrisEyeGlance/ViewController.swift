//
//  ViewController.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2022/10/12.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, TrackerDelegate {
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let camera = Camera()
//    let tracker: SYFaceMesh = SYFaceMesh()!
    var frameNum: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        camera.setSampleBufferDelegate(self)
        camera.start()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer!))
        }
        frameNum += 1
        label.text = "\(frameNum)"
    }
    
    
}

