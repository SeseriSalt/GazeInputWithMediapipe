//
//  Initialization.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2023/07/28.
//

import Foundation

extension ViewController {
    func glanceInit() {
        glanceFlag = 0
        glanceFirstPoint = 0
        firstDirect = 0.0
        firstDirectIris = lrPoint(l: 0.0, r: 0.0)
        secondDirect = 0.0
        secondDirectIris = lrPoint(l: 0.0, r: 0.0)
    }
    
    func winkInit() {
        winkFlag = 0
        lateWinkFlag = 0
        maxDiff = 0
        minDiff = 0
        maxPeakFrameNum = 0
        minPeakFrameNum = 0
        peakPrev = 0
        peakNext = 0
    }
    
    func allInit() {
        brinkFlag = 0
        
        moveMissjudgeFlag = 0
        winkInit()
        
        glanceInit()
    }
}
