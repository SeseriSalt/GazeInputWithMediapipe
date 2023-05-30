//
//  InputScreenUI.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/05/23.
//

import Foundation
import UIKit

extension ViewController {
    
    // 矩形の情報を得るための構造体
    struct RectInfo {
        var center: CGPoint
        var width: CGFloat
        var height: CGFloat
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        design1.center = CGPoint(x: design1.center.x + translation.x, y: design1.center.y + translation.y)
        noseLabel.center = CGPoint(x: noseLabel.center.x + translation.x, y: noseLabel.center.y + translation.y)
        gesture.setTranslation(.zero, in: view)
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        tapCount += 1
        
        if tapCount >= imageSizeList.count {
            tapCount = 0
        }
        
        updateImageViewSize()
    }
    
    func updateImageViewSize() {
        let imageSize = imageSizeList[tapCount]
        let center = design1.center
        let labelHeight = center.y - CGFloat(imageSize.1) / 2 - 11.0
        
        design1.frame.size = CGSize(width: imageSize.0, height: imageSize.1)
        design1.center = center
        noseLabel.center = CGPoint(x: center.x, y: labelHeight)
    }
    
    func getScreenInfo() -> RectInfo {
        let screenInfo = RectInfo(center: design1.center, width: design1.bounds.width, height: design1.bounds.height)
        DispatchQueue.main.async {
            self.ISCenterLabel.text = "x:\(round(screenInfo.center.x*10)/10) y:\(round(screenInfo.center.y*10)/10)"
            self.ISWidthLabel.text = "Width:\(screenInfo.width)"
        }
//        print("center: \(screenInfo.center), width: \(screenInfo.width), Height: \(screenInfo.height)")
        return screenInfo
    }
}
