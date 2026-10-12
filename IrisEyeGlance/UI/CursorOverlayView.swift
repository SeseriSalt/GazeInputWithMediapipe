//
//  CursorOverlayView.swift
//  IrisEyeGlance
//
//  Draws the nose cursor with a single reusable layer.
//

import UIKit

final class CursorOverlayView: UIView {
    private let dot = CAShapeLayer()
    private let radius: CGFloat = 4

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        dot.path = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        dot.fillColor = UIColor.systemBlue.cgColor
        dot.strokeColor = UIColor.white.cgColor
        dot.lineWidth = 1
        dot.isHidden = true
        layer.addSublayer(dot)
        isAccessibilityElement = true
        accessibilityLabel = "鼻のカーソル"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func update(point: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dot.position = point
        dot.isHidden = false
        CATransaction.commit()
        accessibilityValue = "x \(Int(point.x)), y \(Int(point.y))"
    }
}
