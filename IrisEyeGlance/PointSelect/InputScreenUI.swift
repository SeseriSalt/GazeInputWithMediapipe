//
//  InputScreenUI.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/05/23.
//

import UIKit
import IrisEyeGlanceCore

extension ViewController {

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        inputDesignImage.center = CGPoint(x: inputDesignImage.center.x + translation.x, y: inputDesignImage.center.y + translation.y)
        inputLabel.center = CGPoint(x: inputLabel.center.x + translation.x, y: inputLabel.center.y + translation.y)
        questionLabel.center = CGPoint(x: questionLabel.center.x + translation.x, y: questionLabel.center.y + translation.y)
        gesture.setTranslation(.zero, in: view)
        panelFrameDidChange()
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
        let center = inputDesignImage.center
        let labelHeight = center.y - CGFloat(imageSize.1) / 2 - 22.0

        let imageSizeCon = imageSizeListCon[tapCount]
        let centerCon = consonantDesignImage.center

        inputDesignImage.frame.size = CGSize(width: imageSize.0, height: imageSize.1)
        inputDesignImage.center = center
        inputLabel.center = CGPoint(x: center.x, y: labelHeight)
        questionLabel.center = CGPoint(x: center.x, y: labelHeight - 22.0)

        consonantDesignImage.frame.size = CGSize(width: imageSizeCon.0, height: imageSizeCon.1)
        consonantDesignImage.center = centerCon
        panelFrameDidChange()
    }

    /// Current panel geometry in view coordinates.
    func currentPanelFrame() -> InputPanelFrame {
        InputPanelFrame(center: inputDesignImage.center,
                        width: inputDesignImage.bounds.width,
                        height: inputDesignImage.bounds.height)
    }

    /// Pushes the panel geometry to the processor and refreshes the debug labels.
    func panelFrameDidChange() {
        let frame = currentPanelFrame()
        ISCenterLabel?.text = "x:\(round(frame.center.x * 10) / 10) y:\(round(frame.center.y * 10) / 10)"
        ISWidthLabel?.text = "Width:\(frame.width)"
        processor.setPanelFrame(processor.calibrationStep == .idle ? frame : nil)
    }
}
