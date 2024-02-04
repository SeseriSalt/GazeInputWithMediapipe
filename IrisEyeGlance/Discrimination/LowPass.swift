//
//  LowPass.swift
//  IrisEyeGlance
//
//  Created by 河野英瑠 on 2023/11/02.
//



import Foundation

public class LowPassFilter {
    private let alpha: Double
    private var lastValue: Double?
    
    public init(cutoffFrequency: Double, sampleRate: Double) {
        let dt = 1.0 / sampleRate // Δt - time between samples
        let rc = 1.0 / (cutoffFrequency * 2 * .pi) // Time constant
        self.alpha = dt / (dt + rc)
    }
    
    public func filter(value: Double) -> Double {
        guard let lastValue = lastValue else {
            // This is the first value, so just return it
            self.lastValue = value
            return value
        }
        
        let filteredValue = alpha * value + (1 - alpha) * lastValue
        self.lastValue = filteredValue
        return filteredValue
    }
}
