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
    var bufferPublisher: AnyPublisher<[Float], Never> { get }
    func detectPitch() -> AnyPublisher<Double, ErrorType>
    func stop()
}

class PitchDetector: PitchDetectorProtocol {
    private let audioCapture: AudioCaptureProtocol
    private let yinYangPitchDetector: YinYangPitchDetectorProtocol
    private let bufferSubject = PassthroughSubject<AVAudioPCMBuffer, Never>()
    
    var bufferPublisher: AnyPublisher<[Float], Never> {
        bufferSubject.map { buffer in
            guard let floatChannelData = buffer.floatChannelData else { return [] }
            let frameCount = Int(buffer.frameLength)
            let signal = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameCount))
                .filter { $0 > 0 }
            return signal.filter { $0 > 0.01 }.count > 100
            ? signal.filter { $0 > 0.01 }
            : signal
        }.eraseToAnyPublisher()
    }

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
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.global(), latest: true)
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .compactMap { [weak self] buffer -> Double? in
                guard let self = self else { return nil }
                return self.processBuffer(buffer)
            }
            .filter { [weak self] in self?.isWithinFrequencyRange($0) ?? false }
            .eraseToAnyPublisher()
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) -> Double? {
        let pitch = yinYangPitchDetector.detectPitch(forBuffer: buffer, sampleRate: audioCapture.sampleRate)
        bufferSubject.send(buffer)
        print("yinYang: \(String(describing: pitch))")
        return pitch
    }

    private func isWithinFrequencyRange(_ pitch: Double) -> Bool {
        return pitch < TuneProvider.maxFrequency && pitch > TuneProvider.minFrequency
    }
}
