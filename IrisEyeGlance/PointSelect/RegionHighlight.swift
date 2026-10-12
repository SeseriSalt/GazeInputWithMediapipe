//
//  RegionHighlight.swift
//  IrisEyeGlance
//
//  Draws the selection border around the region under the cursor and shows the
//  matching row hint image. The region itself is resolved by `InputRegionResolver`.
//

import UIKit
import IrisEyeGlanceCore

extension ViewController {

    /// Row hint image names keyed by region, for the Japanese and alphabet panels.
    private static let japaneseRowImages: [Int: String] = [
        1: "rowA", 2: "rowK", 3: "rowS", 5: "rowT", 6: "rowN", 7: "rowH",
        9: "rowM", 10: "rowY", 11: "rowR", 14: "rowW", 15: "rowX",
    ]
    private static let alphabetRowImages: [Int: String] = [
        1: "row2At", 2: "row2A", 3: "row2D", 5: "row2G", 6: "row2J", 7: "row2M",
        9: "row2P", 10: "row2T", 11: "row2W", 14: "row2\"\"", 15: "row2?!",
    ]

    @MainActor
    func showRegion(_ region: Int, rect: CGRect?, layout: KeyboardLayout) {
        guard region != 0, let rect else {
            rectLayer?.removeFromSuperlayer()
            rectLayer = nil
            consonantDesignImage.image = nil
            return
        }
        drawSelectionBorder(rect)
        let images = layout.isAlphabet ? ViewController.alphabetRowImages : ViewController.japaneseRowImages
        if let name = images[region] {
            consonantDesignImage.image = UIImage(named: name)
            consonantDesignImage.center = CGPoint(x: rect.midX, y: rect.midY)
        } else {
            consonantDesignImage.image = nil
        }
    }

    @MainActor
    func drawSelectionBorder(_ rect: CGRect) {
        let path = UIBezierPath(rect: rect)
        let layer = rectLayer ?? CAShapeLayer()
        layer.path = path.cgPath
        layer.lineWidth = lineWidthList[tapCount]
        layer.strokeColor = UIColor(red: 26/255, green: 128/255, blue: 133/255, alpha: 1.0).cgColor
        layer.fillColor = UIColor.clear.cgColor
        if layer.superlayer == nil {
            view.layer.addSublayer(layer)
        }
        rectLayer = layer
    }
}
