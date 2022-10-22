//
//  ViewController.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2022/10/12.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, SYFaceMeshDelegate {
    
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let camera = Camera()
    let tracker: SYFaceMesh = SYFaceMesh()!
    var frameNum: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        camera.setSampleBufferDelegate(self)
        camera.start()
        tracker.startGraph()
        tracker.delegate = self
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        tracker.processVideoFrame(pixelBuffer)
        
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer!))
        }
        frameNum += 1
        label.text = "\(frameNum)"
    }
    
    func faceMeshTracker(_ faceMeshTracker: SYFaceMesh!, didOutputLandmarks landmarks: [Landmark]!) {
        print("!!!!!!!!!!!!\(frameNum)!!!!!!!!!!!!!")
        if let unwrapped = landmarks {
            for (i, point) in unwrapped.enumerated() {
                print("\(i): \(point.x), \(point.y), \(point.z)")
            }
        }
    }
    
    func faceMeshTracker(_ faceMeshTracker: SYFaceMesh!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        DispatchQueue.main.async {
            self.imageview.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
        }
    }
}

