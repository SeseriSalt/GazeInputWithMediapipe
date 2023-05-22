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
        gesture.setTranslation(.zero, in: view)
    }
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        if gesture.state == .changed {
            let pinchCenter = CGPoint(x: gesture.location(in: view).x - view.bounds.midX,
                                      y: gesture.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: gesture.scale, y: gesture.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            
            view.transform = transform
            gesture.scale = 1.0
        }
    }
    
    func getScreenInfo() -> RectInfo {
        let screenInfo = RectInfo(center: design1.center, width: design1.bounds.width, height: design1.bounds.height)
//        print("width: \(screenInfo.width), Height: \(screenInfo.height)")
        return screenInfo
    }
}
