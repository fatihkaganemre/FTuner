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

    func detectPitch() -> AnyPublisher<Double, ErrorType> {
        return audioCapture
            .askMicrophonePermission()
            .flatMap { [weak self] in return self?.audioCapture.startRecording() ?? Empty().eraseToAnyPublisher() }
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .compactMap { [weak self] buffer -> Double? in
                guard let self = self else { return nil }
                return self.processBuffer(buffer)
            }
            .filter { [weak self] in self?.isWithinFrequencyRange($0) ?? false }
            .eraseToAnyPublisher()
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) -> Double? {
        let pitch = yinYangPitchDetector.detectPitch(forBuffer: buffer, sampleRate: audioCapture.sampleRate)
        print("yinYang: \(String(describing: pitch))")
        return pitch
    }

    private func isWithinFrequencyRange(_ pitch: Double) -> Bool {
        return pitch < maxFrequency && pitch > minFrequency
    }
}
