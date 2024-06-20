//
//  TunesChartView.swift
//  FTuner
//
//  Created by Fatih Kagan Emre on 25/05/2024.
//

import SwiftUI
import Charts

struct TunesChartView: View {
    @Binding var buffer: [Float]
    
    var body: some View {
        Chart(normalise(data: buffer).indices, id: \.self) { index in
            AreaMark(
                x: .value("Time", index),
                y: .value("Frequency", buffer[index])
            )
            .foregroundStyle(gradientColor(for: buffer[index]))
        }
        .chartYScale(domain: 0...0.1)
        .frame(maxHeight: 300)
        .animation(.smooth, value: buffer)
    }
    
    func gradientColor(for value: Float) -> LinearGradient {
        let gradientColors = Gradient(colors: [Color.blue, Color.green, Color.yellow, Color.red])
        return LinearGradient(
            gradient: gradientColors,
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    private func normalise(data: [Float]) -> [Float] {
        guard let min = data.min(), let max = data.max(), min != max else {
            return data // If all values are the same, return the original array
        }
        
        return data.map { ($0 - min) / (max - min) }
    }
}

#Preview {
    TunesChartView(buffer: .constant([200, 20, 50, 100, 20, 350, 240, 1000, 149]))
}
