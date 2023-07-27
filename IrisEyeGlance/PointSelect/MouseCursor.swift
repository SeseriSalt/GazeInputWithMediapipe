//
//  MouseCursor.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/05/23.
//

import Foundation
import UIKit

public var circleLayer: CAShapeLayer?

extension ViewController {
    
    @objc func drawCursor(point: CGPoint) {
        let circleRadius: CGFloat = 2.5
        
        let circlePath = UIBezierPath(arcCenter: point, radius: circleRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.blue.cgColor
        
        // すでに円が描画されている場合、過去の円を削除
        if let oldCircleLayer = circleLayer {
            oldCircleLayer.removeFromSuperlayer()
        }
        
        view.layer.addSublayer(shapeLayer)
        
        circleLayer = shapeLayer
    }
}





