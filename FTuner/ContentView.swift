//
//  ContentView.swift
//  FTuner
//
//  Created by Fatih Kagan Emre on 18/05/2024.
//

import SwiftUI
import Combine

@Observable class ViewModel {
    var tuneName: String = "C0"
    var frequencyDifference: Double = 5
    var differenceText: String = "-4.245"
    var color: Color = .green
    var isLoading: Bool = false
    var showAlert: Bool = false
    
    private let pitchDetector: PitchDetectorProtocol
    private var cancellableSet = Set<AnyCancellable>()
    private var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 3
        return formatter
    }
    
    deinit {
        pitchDetector.stop()
    }
    
    init(pitchDetector: PitchDetectorProtocol = PitchDetector()) {
        self.pitchDetector = pitchDetector
    }
    
    func startPitchDetection() {
        pitchDetector.detectPitch()
            .sink { [weak self] completion in
                self?.isLoading = false
            } receiveValue: { [weak self] pitch in
                guard let self = self else { return }
                guard let (tune, difference) = getTuneAndDifference(fromFrequency: pitch) else { return }

                differenceText = formatter.string(from: difference as NSNumber) ?? ""
                frequencyDifference = difference
                tuneName = tune
                isLoading = false
                color = getTheColorOfDetectedPitch(pitch)
            }
            .store(in: &cancellableSet)
    }
    
    private func getTheColorOfDetectedPitch(_ pitch: Double) -> Color {
        guard let percentage = calculateTheDifferencePercentage(ofFrequency: pitch) else { return .red }
        switch percentage {
            case ..<10: return .green
            case 10..<15: return .yellow
            case 15...: return .red
            default: return .red
        }
    }
}

struct ContentView: View {
    @State var model = ViewModel()
    
    var body: some View {
        if model.isLoading {
            ProgressView().progressViewStyle(.circular)
        } else {
            TuneView(model: model)
                .padding()
                .onAppear(perform: {
                    model.startPitchDetection()
                })
        }
    }
}

#Preview {
    ContentView()
}
