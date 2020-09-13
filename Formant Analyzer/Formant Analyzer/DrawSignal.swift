//
//  DrawSignal.swift
//  Formant Analyzer
//
//  Created by William Entriken on 11.09.2020.
//  Copyright © 2020 William Entriken. All rights reserved.
//

import SwiftUI
import FSLineChart

struct drawSignalPlot: UIViewRepresentable {
    
    let plottableValues: [Double]
    let size: CGSize
    let strongPartFirst: Int
    let strongPartCount: Int
    let vowelPartFirst: Int
    let vowelPartCount: Int
    let samplesCount: Int
    
    func makeUIView(context: Context) -> FSLineChart {
        FSLineChart()
    }
    
    // a function which updated th UIKit thing when appropriate (bindings change, etc.)
    func updateUIView(_ lineChart: FSLineChart, context: Context) {
        
        lineChart.drawInnerGrid = false
        lineChart.axisLineWidth = 0
        lineChart.margin = 0
        lineChart.axisWidth = size.width
        lineChart.axisHeight = size.height
        lineChart.backgroundColor = UIColor.clear
        lineChart.fillColor = UIColor.blue
        lineChart.clearData()
        lineChart.setChartData(plottableValues)
        
        lineChart.subviews.forEach({$0.removeFromSuperview()})
        
        let strongRect = CGRect(
            x: CGFloat(size.width) * CGFloat(strongPartFirst) / CGFloat(samplesCount),
            y: 0,
            width: CGFloat(size.width) * CGFloat(strongPartCount) / CGFloat(samplesCount),
            height: size.height)
        
        let strongBox = UIView(frame: strongRect)
        strongBox.backgroundColor = UIColor(hue: 60.0/255.0, saturation: 180.0/255.0, brightness: 92.0/255.0, alpha: 0.2)
        lineChart.insertSubview(strongBox, at: 0)
        
        let vowelRect = CGRect(
            x: CGFloat(size.width) * CGFloat(vowelPartFirst) / CGFloat(samplesCount),
            y: 0,
            width: CGFloat(size.width) * CGFloat(vowelPartCount) / CGFloat(samplesCount),
            height: size.height)
        
        let vowelBox = UIView(frame: vowelRect)
        vowelBox.backgroundColor = UIColor(hue: 130.0/255.0, saturation: 180.0/255.0, brightness: 92.0/255.0, alpha: 0.2)
        lineChart.insertSubview(vowelBox, at: 0)
        
        
    }
}


struct drawLPCPlot: UIViewRepresentable {
    
    let lpcCoefficients: [Double]
    let size: CGSize
    
    func makeUIView(context: Context) -> FSLineChart {
        FSLineChart()
    }
    
    // a function which updated th UIKit thing when appropriate (bindings change, etc.)
    func updateUIView(_ lineChart: FSLineChart, context: Context) {
        
        // Index label properties
        lineChart.labelForIndex = {
            (item: UInt) -> String in
            return "\(Int(item))"
        }
        // Value label properties
        lineChart.labelForValue = {
            (value: CGFloat) -> String in
            return String(format: "%.02f", value)
        }
        lineChart.valueLabelPosition = .left
        // Number of visible step in the chart
        lineChart.verticalGridStep = 3
        lineChart.horizontalGridStep = 20
        // Margin of the chart
        lineChart.margin = 40
        lineChart.axisWidth = size.width - 2 * lineChart.margin
        lineChart.axisHeight = size.height - 2 * lineChart.margin
        // Decoration parameters, let you pick the color of the line as well as the color of the axis
        lineChart.axisLineWidth = 1
        // Chart parameters
        lineChart.color = UIColor.black
        lineChart.fillColor = UIColor.blue
        lineChart.backgroundColor = UIColor.clear
        // Grid parameters
        lineChart.drawInnerGrid = true
        
        lineChart.clearData()
        lineChart.setChartData(lpcCoefficients)
    }
}

struct drawHwPlot: UIViewRepresentable {
    
    let synthesizedFrequencyResponse: [Double]
    let size: CGSize
    
    func makeUIView(context: Context) -> FSLineChart {
        FSLineChart()
    }
    
    // a function which updated th UIKit thing when appropriate (bindings change, etc.)
    func updateUIView(_ lineChart: FSLineChart, context: Context) {
        
       // Index label properties
        lineChart.labelForIndex = {
            (item: UInt) -> String in
            return String(format: "%.0f kHz", Double(item) / 60)
        }
        // Value label properties
        lineChart.labelForValue = {
            (value: CGFloat) -> String in
            return String(format: "%.02f", value)
        }
        lineChart.valueLabelPosition = .left
        // Number of visible steps in the chart
        lineChart.verticalGridStep = 3
        lineChart.horizontalGridStep = 5
        // Margin of the chart
        lineChart.margin = 40
        lineChart.axisWidth = size.width - 2 * lineChart.margin
        lineChart.axisHeight = size.height - 2 * lineChart.margin
        // Decoration parameters, let you pick the color of the line as well as the color of the axis
        lineChart.axisLineWidth = 1
        // Chart parameters
        lineChart.color = UIColor.black
        lineChart.fillColor = UIColor.blue
        lineChart.backgroundColor = UIColor.clear
        // Grid parameters
        lineChart.drawInnerGrid = true
        
        lineChart.clearData()
        lineChart.setChartData(synthesizedFrequencyResponse)
    }
}
