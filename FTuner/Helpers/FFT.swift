//
//  FFT.swift
//  FTuner
//
//  Created by Fatih Kagan Emre on 19/05/2024.
//

import Foundation
import Accelerate

// Function to perform FFT
func performFFT(inputArray: [Float]) -> [Float] {
    let log2n = UInt(round(log2(Double(inputArray.count))))
    let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))!
    
    var realp = [Float](repeating: 0, count: inputArray.count / 2)
    var imagp = [Float](repeating: 0, count: inputArray.count / 2)
    
    realp.withUnsafeMutableBufferPointer { realpPtr in
        imagp.withUnsafeMutableBufferPointer { imagpPtr in
            inputArray.withUnsafeBufferPointer { inputPtr in
                var splitComplex = DSPSplitComplex(realp: realpPtr.baseAddress!, imagp: imagpPtr.baseAddress!)
                inputPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: inputArray.count / 2) {
                    vDSP_ctoz($0, 2, &splitComplex, 1, vDSP_Length(inputArray.count / 2))
                }
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, Int32(FFT_FORWARD))
            }
        }
    }
    
    var magnitudes = [Float](repeating: 0.0, count: inputArray.count / 2)
    var splitComplex = DSPSplitComplex(realp: &realp, imagp: &imagp)
    let dspLength = vDSP_Length(inputArray.count / 2)
    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, dspLength)
    vDSP_destroy_fftsetup(fftSetup)
    return magnitudes
}
