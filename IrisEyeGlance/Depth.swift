//
//  Depth.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2022/10/29.
//

import Foundation

public let VER_IRIS_SIZE: Float = 11.8

func getLength(x0: Float, y0: Float, x1: Float, y1: Float) -> Float {
    return sqrt((x0 - x1) * (x0 - x1) + (y0 - y1) * (y0 - y1))
}

func getLandmerkLength(point0: [Float], point1: [Float], imageSize: [Float]) -> Float {
    return getLength(x0: point0[0] * imageSize[0], y0: point0[1] * imageSize[1],
                    x1: point1[0] * imageSize[0], y1: point1[1] * imageSize[1])
}

func caluclateIrisDiamater(landmark: [[Float]], imageSize: [Float]) -> Float {
    let distVert = getLandmerkLength(point0: landmark[2], point1: landmark[4], imageSize: imageSize)
    let distHori = getLandmerkLength(point0: landmark[1], point1: landmark[3], imageSize: imageSize)
    return (distVert + distHori) / 2.0
}

func caluclateDepth(centerPoint: [Float], focalLength: Float, irisSize: Float, width: Float, height: Float) -> Float {
    let origin = [width / 2.0, height / 2.0]
    let y = getLength(x0: origin[0], y0: origin[1], x1: centerPoint[0] * width, y1: centerPoint[1] * height)
    let x = sqrt(focalLength * focalLength + y * y)
    let depth = VER_IRIS_SIZE * x / irisSize
    return depth
}
