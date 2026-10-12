//
//  MouseCursor.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/05/23.
//

import UIKit

extension ViewController {

    /// Draws the nose cursor, reusing a single layer.
    @MainActor
    func drawCursor(point: CGPoint) {
        let circleRadius: CGFloat = 2.5
        let circlePath = UIBezierPath(arcCenter: point, radius: circleRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)

        let layer = circleLayer ?? CAShapeLayer()
        layer.path = circlePath.cgPath
        layer.fillColor = UIColor.blue.cgColor
        if layer.superlayer == nil {
            view.layer.addSublayer(layer)
        }
        circleLayer = layer
    }
}
