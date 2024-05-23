////
////  AudioCapture.swift
////  FTuner
////
////  Created by Fatih Kagan Emre on 18/05/2024.
////

import AVFoundation
import Combine


protocol AudioCaptureProtocol {
    var sampleRate: Double { get }
    func startRecording() -> AnyPublisher<AVAudioPCMBuffer, ErrorType>
    func stopRecording()
    func askMicrophonePermission() async throws -> Bool
}

class AudioCapture: AudioCaptureProtocol {
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    
    var sampleRate: Double {
        audioEngine.inputNode.inputFormat(forBus: 0).sampleRate
    }
    
    func askMicrophonePermission() -> AnyPublisher<Bool, ErrorType> {
        Future
        return await AVAudioApplication.requestRecordPermission()
    }
    
    func startRecording() -> AnyPublisher<AVAudioPCMBuffer, ErrorType> {
        let bufferPublisher = PassthroughSubject<AVAudioPCMBuffer, ErrorType>()
        do {
            try setAudioSession()
        } catch {
            bufferPublisher.send(completion: .failure(.sessionError))
        }
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            bufferPublisher.send(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            bufferPublisher.send(completion: .failure(.engineError))
        }
        return bufferPublisher.eraseToAnyPublisher()
    }
    
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    private func setAudioSession() throws {
        try audioSession.setCategory(.record)
        try audioSession.setActive(true)
    }
}
