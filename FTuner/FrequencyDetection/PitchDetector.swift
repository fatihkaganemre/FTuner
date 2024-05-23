//
//  PitchDetector.swift
//  FTuner
//
//  Created by Fatih Kagan Emre on 18/05/2024.
//

import AVFoundation
import Combine
import CoreML

protocol PitchDetectorProtocol {
    func detectPitch() -> AnyPublisher<Double, ErrorType>
    func stop()
}

// Assuming PitchDetection is the name of your Core ML model class
class PitchDetector: PitchDetectorProtocol {
    private let audioCapture: AudioCaptureProtocol
    private let yinYangPitchDetector: YinYangPitchDetectorProtocol

    init(
        audioCapture: AudioCaptureProtocol = AudioCapture(),
        yinYangPitchDetector: YinYangPitchDetectorProtocol = YinYangPitchDetector()
    ) {
        self.audioCapture = audioCapture
        self.yinYangPitchDetector = yinYangPitchDetector
    }
    
    func stop() {
        audioCapture.stopRecording()
    }

    // Perform pitch detection
    func detectPitch() -> AnyPublisher<Double, ErrorType> {
        Task {
            do {
                let isPermitted = try await audioCapture.askMicrophonePermission()
                //isPermitted ? startRecording() : showAlert()
                
            } catch {
                 //  showAlert: print(error)
            }
        }
        
        return audioCapture
            .startRecording()
            .debounce(for: .milliseconds(10), scheduler: DispatchQueue.main)
            .map { [weak self] buffer -> Double? in
                guard let self = self else { return nil }
                let yinYangPitch = self.yinYangPitchDetector.detectPitch(forBuffer: buffer, sampleRate: self.audioCapture.sampleRate)
                print("yinYang: \(yinYangPitch)")
                return yinYangPitch
            }
            .compactMap { $0 }
            .filter { $0 < maxFrequency && $0 > minFrequency }
            .eraseToAnyPublisher()
    }
}
