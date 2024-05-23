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
    var frequencyDifference: Double = -5
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
                if let (tune, difference) = getTuneAndDifference(fromFrequency: pitch) {
                    self?.differenceText = self?.formatter.string(from: difference as NSNumber) ?? ""
                    self?.frequencyDifference = difference
                    self?.color = .red
                    self?.tuneName = tune
                    self?.isLoading = false
                }
            }
            .store(in: &cancellableSet)
    }
}

struct ContentView: View {
    var model = ViewModel()
    
    var body: some View {
        if model.isLoading {
            ProgressView().progressViewStyle(.circular)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 20){
                if model.frequencyDifference < 0 {
                    Text(String(model.differenceText)).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                }
                Text(model.tuneName).font(.system(size: 100))
                    .foregroundColor(model.color)
                if model.frequencyDifference > 0 {
                    Text(String(model.differenceText)).font(.title)
                }
            }
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
