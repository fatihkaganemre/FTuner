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
    func startRecordingAsync() async throws -> AsyncThrowingStream<AVAudioPCMBuffer, Error>
    func startRecording() -> AnyPublisher<AVAudioPCMBuffer, ErrorType>
    func stopRecording()
    func askMicrophonePermissionAsync() async throws
    func askMicrophonePermission() -> AnyPublisher<Void, ErrorType>
}

class AudioCapture: AudioCaptureProtocol {
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    
    var sampleRate: Double {
        audioEngine.inputNode.inputFormat(forBus: 0).sampleRate
    }
    
    
    func askMicrophonePermissionAsync() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            AVAudioApplication.requestRecordPermission { isAllowed in
                if isAllowed {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: ErrorType.noMicPermission)
                }
            }
        }
    }
    
    func askMicrophonePermission() -> AnyPublisher<Void, ErrorType> {
        Future<Void, ErrorType> { promise in
            AVAudioApplication.requestRecordPermission { isAllowed in
                if isAllowed {
                    promise(.success(()))
                } else {
                    promise(.failure(ErrorType.noMicPermission))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func startRecordingAsync() async throws -> AsyncThrowingStream<AVAudioPCMBuffer, Error>  {
        return AsyncThrowingStream<AVAudioPCMBuffer, Error> { continuation in
            do {
                try setAudioSession()
            } catch {
                continuation.finish(throwing: ErrorType.sessionError)
            }
            
            let inputNode = audioEngine.inputNode
            let format = inputNode.inputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 512, format: format) { buffer, _ in
                continuation.yield(buffer)
            }
            
            do {
                try audioEngine.start()
            } catch {
                continuation.finish(throwing: ErrorType.engineError)
            }
        }
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
        inputNode.installTap(onBus: 0, bufferSize: 512, format: format) { buffer, _ in
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
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }
    
    private func setAudioSession() throws {
        try audioSession.setCategory(.record)
        try audioSession.setActive(true)
    }
}
