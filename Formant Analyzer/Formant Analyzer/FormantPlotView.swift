//
//  FormantPlotView.swift
//  FormantPlotter
//
//  Created by William Entriken on 12.09.2020.
//  Copyright © 2020 William Entriken. All rights reserved.
//

import SwiftUI

/// A SwiftUI view that displays a formant plot with markers for F1/F2 or F1/F3.
struct drawFormantPlot: View {
    let plottingF1: Double?
    let plottingF2: Double?
    let plottingF3: Double?
    
    private let markerSize: CGFloat = 15
    private let markerOffset: CGFloat = 7.5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = UIImage(named: "vowelPlotBackground") {
                    Image(uiImage: image)
                        .resizable()
                        .cornerRadius(5)
                } else {
                    Color.gray
                        .cornerRadius(5)
                }
                
                if let f1 = plottingF1, let f2 = plottingF2 {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: markerSize, height: markerSize)
                        .offset(x: geometry.size.width * CGFloat(f1) - markerOffset, y: geometry.size.height * CGFloat(f2) - markerOffset)
                }
                
                if let f1 = plottingF1, let f3 = plottingF3 {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: markerSize, height: markerSize)
                        .offset(x: geometry.size.width * CGFloat(f1) - markerOffset, y: geometry.size.height * CGFloat(f3) - markerOffset)
                }
            }
        }
    }
}
