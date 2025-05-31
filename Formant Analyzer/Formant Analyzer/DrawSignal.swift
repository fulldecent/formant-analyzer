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
    let strongPartFirst: Int
    let strongPartCount: Int
    let vowelPartFirst: Int
    let vowelPartCount: Int
    let samplesCount: Int

    func makeUIView(context: Context) -> FSLineChart {
        let chart = FSLineChart()
        // (You can also enforce clipping here if you like)
        chart.clipsToBounds = true
        return chart
    }

    func updateUIView(_ lineChart: FSLineChart, context: Context) {
        // 1) Re‐apply the style & data exactly as before:
        let style = ChartStyle(
            axisColor: .clear,
            axisLineWidth: 0,
            lineColor: .blue,
            fillColor: UIColor.blue.withAlphaComponent(0.5),
            lineWidth: 1,
            displayDataPoints: false,
            dataPointColor: .blue,
            dataPointBackgroundColor: .blue,
            dataPointRadius: 0,
            drawInnerGrid: false,
            innerGridColor: .clear,
            innerGridLineWidth: 0,
            gridSteps: (vertical: 1, horizontal: 1),
            margin: 0,
            bezierSmoothing: true,
            bezierSmoothingTension: 0.2,
            animationDuration: 0.5,
            indexLabelFont: .systemFont(ofSize: 10),
            indexLabelColor: .clear,
            indexLabelBackgroundColor: .clear,
            valueLabelFont: .systemFont(ofSize: 11),
            valueLabelColor: .clear,
            valueLabelBackgroundColor: .clear,
            valueLabelPosition: .right
        )
        lineChart.applyStyle(style)
        lineChart.setLabels(nil)
        lineChart.backgroundColor = .clear

        do {
            try lineChart.setChartData(plottableValues)
        } catch {
            NSLog("Failed to set signal plot data: \(error)")
        }

        // 2) Delete any old highlight‐subviews before adding new ones:
        lineChart.subviews.forEach { $0.removeFromSuperview() }

        // 3) Ask UIKit how big this chart really is right now:
        let chartSize = lineChart.bounds.size

        // 4) Compute the “strong” highlight rectangle using chartSize:
        let strongRect = CGRect(
            x: chartSize.width * CGFloat(strongPartFirst) / CGFloat(max(1, samplesCount)),
            y: 0,
            width: chartSize.width * CGFloat(strongPartCount) / CGFloat(max(1, samplesCount)),
            height: chartSize.height
        )
        let strongBox = UIView(frame: strongRect)
        strongBox.backgroundColor = UIColor(
            hue: 60.0/255.0,
            saturation: 180.0/255.0,
            brightness: 92.0/255.0,
            alpha: 0.2
        )
        lineChart.insertSubview(strongBox, at: 0)

        // 5) Compute the “vowel” highlight rectangle the same way:
        let vowelRect = CGRect(
            x: chartSize.width * CGFloat(vowelPartFirst) / CGFloat(max(1, samplesCount)),
            y: 0,
            width: chartSize.width * CGFloat(vowelPartCount) / CGFloat(max(1, samplesCount)),
            height: chartSize.height
        )
        let vowelBox = UIView(frame: vowelRect)
        vowelBox.backgroundColor = UIColor(
            hue: 130.0/255.0,
            saturation: 180.0/255.0,
            brightness: 92.0/255.0,
            alpha: 0.2
        )
        lineChart.insertSubview(vowelBox, at: 0)
    }
}

/// A SwiftUI view that displays an LPC coefficients plot with grid and labels.
struct drawLPCPlot: UIViewRepresentable {
    let lpcCoefficients: [Double]
    let size: CGSize
    
    func makeUIView(context: Context) -> FSLineChart {
        FSLineChart()
    }
    
    /// Updates the chart with the current LPC coefficients and configuration.
    func updateUIView(_ lineChart: FSLineChart, context: Context) {
        // Configure labels
        let labels = ChartLabels(
            indexLabel: { "\($0)" },
            valueLabel: { String(format: "%.02f", $0) }
        )
        lineChart.setLabels(labels)
        
        // Configure style
        let style = ChartStyle(
            axisColor: .gray,
            axisLineWidth: 1,
            lineColor: .black,
            fillColor: UIColor.blue.withAlphaComponent(0.5),
            lineWidth: 1,
            displayDataPoints: false,
            dataPointColor: .black,
            dataPointBackgroundColor: .black,
            dataPointRadius: 0,
            drawInnerGrid: true,
            innerGridColor: UIColor(white: 0.9, alpha: 1.0),
            innerGridLineWidth: 0.5,
            gridSteps: (vertical: 3, horizontal: 20),
            margin: 40,
            bezierSmoothing: true,
            bezierSmoothingTension: 0.2,
            animationDuration: 0.5,
            indexLabelFont: .systemFont(ofSize: 10),
            indexLabelColor: .gray,
            indexLabelBackgroundColor: .clear,
            valueLabelFont: .systemFont(ofSize: 11),
            valueLabelColor: .gray,
            valueLabelBackgroundColor: UIColor(white: 1, alpha: 0.75),
            valueLabelPosition: .left
        )
        lineChart.applyStyle(style)
        
        // Set data
        lineChart.backgroundColor = .clear
        do {
            try lineChart.setChartData(lpcCoefficients)
        } catch {
            NSLog("Failed to set LPC plot data: \(error)")
        }
    }
}

/// A SwiftUI view that displays a synthesized frequency response plot with frequency labels.
struct drawHwPlot: UIViewRepresentable {
    let synthesizedFrequencyResponse: [Double]
    let size: CGSize
    
    func makeUIView(context: Context) -> FSLineChart {
        FSLineChart()
    }
    
    /// Updates the chart with the current frequency response and configuration.
    func updateUIView(_ lineChart: FSLineChart, context: Context) {
        // Configure labels
        let labels = ChartLabels(
            indexLabel: { String(format: "%.0f kHz", Double($0) / 60) },
            valueLabel: { String(format: "%.02f", $0) }
        )
        lineChart.setLabels(labels)
        
        // Configure style
        let style = ChartStyle(
            axisColor: .gray,
            axisLineWidth: 1,
            lineColor: .black,
            fillColor: UIColor.blue.withAlphaComponent(0.5),
            lineWidth: 1,
            displayDataPoints: false,
            dataPointColor: .black,
            dataPointBackgroundColor: .black,
            dataPointRadius: 0,
            drawInnerGrid: true,
            innerGridColor: UIColor(white: 0.9, alpha: 1.0),
            innerGridLineWidth: 0.5,
            gridSteps: (vertical: 3, horizontal: 5),
            margin: 40,
            bezierSmoothing: true,
            bezierSmoothingTension: 0.2,
            animationDuration: 0.5,
            indexLabelFont: .systemFont(ofSize: 10),
            indexLabelColor: .gray,
            indexLabelBackgroundColor: .clear,
            valueLabelFont: .systemFont(ofSize: 11),
            valueLabelColor: .gray,
            valueLabelBackgroundColor: UIColor(white: 1, alpha: 0.75),
            valueLabelPosition: .left
        )
        lineChart.applyStyle(style)
        
        // Set data
        lineChart.backgroundColor = .clear
        do {
            try lineChart.setChartData(synthesizedFrequencyResponse)
        } catch {
            NSLog("Failed to set frequency response plot data: \(error)")
        }
    }
}
