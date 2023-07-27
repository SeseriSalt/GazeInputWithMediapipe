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
        imputDesignImage.center = CGPoint(x: imputDesignImage.center.x + translation.x, y: imputDesignImage.center.y + translation.y)
        inputLabel.center = CGPoint(x: inputLabel.center.x + translation.x, y: inputLabel.center.y + translation.y)
        questionLabel.center = CGPoint(x: questionLabel.center.x + translation.x, y: questionLabel.center.y + translation.y)
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
        let center = imputDesignImage.center
        let labelHeight = center.y - CGFloat(imageSize.1) / 2 - 11.0
        
        imputDesignImage.frame.size = CGSize(width: imageSize.0, height: imageSize.1)
        imputDesignImage.center = center
        inputLabel.center = CGPoint(x: center.x, y: labelHeight)
        questionLabel.center = CGPoint(x: center.x, y: labelHeight - 22.0)
    }
    
    func getScreenInfo() -> RectInfo {
        let screenInfo = RectInfo(center: imputDesignImage.center, width: imputDesignImage.bounds.width, height: imputDesignImage.bounds.height)
        DispatchQueue.main.async {
            self.ISCenterLabel.text = "x:\(round(screenInfo.center.x*10)/10) y:\(round(screenInfo.center.y*10)/10)"
            self.ISWidthLabel.text = "Width:\(screenInfo.width)"
        }
//        print("center: \(screenInfo.center), width: \(screenInfo.width), Height: \(screenInfo.height)")
        return screenInfo
    }
}
