//
//  YinYang.swift
//  FTuner
//
//  Created by Fatih Kagan Emre on 18/05/2024.
//

import Foundation
import Accelerate
import AVFoundation

protocol YinYangPitchDetectorProtocol {
    func detectPitch(forBuffer buffer: AVAudioPCMBuffer, sampleRate: Double) -> Double?
}

class YinYangPitchDetector: YinYangPitchDetectorProtocol {

    func detectPitch(forBuffer buffer: AVAudioPCMBuffer, sampleRate: Double) -> Double? {
        guard let floatChannelData = buffer.floatChannelData else { return nil }

        let frameCount = Int(buffer.frameLength)
        let inputArray = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameCount))
        
        // Set tauMax to half the frame count or any suitable value based on your requirements
        let tauMax = frameCount / 2
        
        // Perform YIN algorithm
        let diff = differenceFunction(inputArray: inputArray, tauMax: tauMax)
        let cmnd = cumulativeMeanNormalizedDifference(diff: diff)
        
        // Use a typical threshold value for YIN algorithm, such as 0.1
        guard let minValue = cmnd.min() else { return nil }
        guard let tau = absoluteThreshold(cmnd: cmnd, threshold: minValue + 0.01) else { return nil }
        let fundamentalFrequency: Double = sampleRate / Double(tau)
        return fundamentalFrequency
    }
    
    private func differenceFunction(inputArray: [Float], tauMax: Int) -> [Float] {
        let n = inputArray.count
        var diff = [Float](repeating: 0, count: tauMax)

        // Parallelize the outer loop using DispatchQueue
        DispatchQueue.concurrentPerform(iterations: tauMax) { tau in
            guard tau > 0 else { return } // Skip tau == 0

            var sum: Float = 0
            for i in 0..<n - tau {
                let delta = inputArray[i] - inputArray[i + tau]
                sum += delta * delta
            }

            diff[tau] = sum
        }

        return diff
    }
    
    // Function to calculate the cumulative mean normalized difference (step 3 of YIN)
    private func cumulativeMeanNormalizedDifference(diff: [Float]) -> [Float] {
        let tauMax = diff.count
        var cmnd = [Float](repeating: 0, count: tauMax)
        cmnd[0] = 1.0
        
        var sum: Float = 0
        for tau in 1..<tauMax {
            sum += diff[tau]
            cmnd[tau] = diff[tau] / ((1.0 / Float(tau)) * sum)
        }
        
        return cmnd
    }
    
    // Function to find the absolute threshold (step 4 and 5 of YIN)
    private func absoluteThreshold(cmnd: [Float], threshold: Float) -> Int? {
        guard let firstBelowThresholdIndex = cmnd.firstIndex(where: { $0 < threshold }) else {
            return nil
        }
        
        var tau = firstBelowThresholdIndex
        while tau + 1 < cmnd.count && cmnd[tau + 1] < cmnd[tau] {
            tau += 1
        }
        
        return tau
    }
}
