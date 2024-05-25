//
//  ContentView.swift
//  FTuner
//
//  Created by Fatih Kagan Emre on 18/05/2024.
//

import SwiftUI
import Charts


struct ContentView: View {
    @State var model = ViewModel()
    
    var body: some View {
        if model.isLoading {
            ProgressView().progressViewStyle(.circular)
                .onAppear {
                    model.startPitchDetection()
                }
        } else {
            VStack {
                TunesChartView(buffer: $model.buffer)
                    .frame(height: 300)
                TuneView(model: model)
                    .frame(height: 100)
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
