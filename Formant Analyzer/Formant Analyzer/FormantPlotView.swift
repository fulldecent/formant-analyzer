//
//  FormantPlotView.swift
//  FormantPlotter
//
//  Created by William Entriken on 12.09.2020.
//  Copyright © 2020 William Entriken. All rights reserved.
//

import SwiftUI

struct drawFormantPlot: View {
    
    let plottingF1: Double?
    let plottingF2: Double?
    let plottingF3: Double?
    
    var body: some View {
        GeometryReader { geometry in
            Image("vowelPlotBackground")
                .resizable()
                .cornerRadius(5)
                .overlay(
                    ZStack(alignment: .topLeading) {
                        if self.plottingF1 != nil && self.plottingF2 != nil {
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 15, height: 15)
                                .offset(x: geometry.size.width * CGFloat(self.plottingF1!) - 7.5, y: geometry.size.height * CGFloat(self.plottingF2!) - 7.5)
                        }
                        
                        if self.plottingF1 != nil && self.plottingF3 != nil {
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 15, height: 15)
                                .offset(x: geometry.size.width * CGFloat(self.plottingF1!) - 7.5, y: geometry.size.height * CGFloat(self.plottingF3!) - 7.5)
                        }
                    },
                    alignment: .topLeading )
        }

    }

}
