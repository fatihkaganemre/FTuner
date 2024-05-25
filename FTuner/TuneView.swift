//
//  TuneView.swift
//  FTuner
//
//  Created by Fatih Kagan Emre on 24/05/2024.
//

import SwiftUI

struct TuneView: View {
    @Bindable var model: ViewModel
    
    var body: some View {
        ZStack {
            Text(model.tuneName).font(.system(size: 100))
                .foregroundColor(model.color)
                .containerRelativeFrame(.vertical, alignment: .center)
            
            HStack(spacing: 20) {
                if model.frequencyDifference < 0 {
                    Text(String(model.differenceText)).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        .frame(maxWidth: 100)
                }
                Spacer()
                if model.frequencyDifference > 0 {
                    Text(String(model.differenceText)).font(.title)
                        .frame(maxWidth: 100)
                }
            }
        }
    }
}

#Preview {
    TuneView(model: .init())
}
