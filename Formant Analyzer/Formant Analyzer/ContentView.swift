//
//  ContentView.swift
//  Formant Analyzer
//
//  Created by William Entriken on 10.09.2020.
//  Copyright © 2020 William Entriken. All rights reserved.
//

import SwiftUI
import ActionOver

/// The main SwiftUI view for the formant analyzer app, displaying audio input controls and plots.
struct ContentView: View {
    @EnvironmentObject var viewModel: FormantAnalyzerViewModel
    @State private var showingActionSheet = false
    
    var body: some View {
        ZStack {
            Color(red: 255.0 / 255, green: 254.0 / 255, blue: 249.0 / 255)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Input controls
                HStack {
                    if viewModel.speechIsFromMicrophone {
                        Image(viewModel.indicatorImage)
                    } else {
                        Image(viewModel.indicatorImage).hidden()
                    }
                    
                    Text(viewModel.statusLabel)
                    Spacer()
                    
                    Button(action: {
                        self.showingActionSheet = true
                    }, label: {
                        Text(viewModel.inputSelector)
                    })
                    .actionOver(
                        presented: $showingActionSheet,
                        title: "Audio source",
                        message: "Select the audio source to analyze",
                        buttons: actionSheetButtons(),
                        ipadAndMacConfiguration: ipadMacConfig,
                        normalButtonColor: UIColor(red: 255.0 / 255, green: 103.0 / 255, blue: 97.0 / 255, alpha: 1)
                    )
                }
                
                // Plot selector
                Picker("Plots", selection: $viewModel.displayIdentifier) {
                    Text("Sig").tag(GraphingMode.signal)
                    Text("LPC").tag(GraphingMode.lpc)
                    Text("H(ω)").tag(GraphingMode.frequencyResponse)
                    Text("Frmnt").tag(GraphingMode.formant)
                }
                .pickerStyle(.segmented)
                
                // Plot display
                GeometryReader { geometry in
                    ZStack {
                        if viewModel.displayIdentifier == .signal && viewModel.speechAnalyzer.samples.count > 0 {
                            drawSignalPlot(
                                plottableValues: viewModel.speechAnalyzer.downsampleToSamples(400).map { Double($0) },
                                strongPartFirst: viewModel.speechAnalyzer.strongPart.first ?? 0,
                                strongPartCount: viewModel.speechAnalyzer.strongPart.count,
                                vowelPartFirst: viewModel.speechAnalyzer.vowelPart.first ?? 0,
                                vowelPartCount: viewModel.speechAnalyzer.vowelPart.count,
                                samplesCount: viewModel.speechAnalyzer.samples.count
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)   // ⬅️ Force fill
                        }

                        if viewModel.displayIdentifier == .lpc {
                            drawLPCPlot(
                                lpcCoefficients: viewModel.speechAnalyzer.estimatedLpcCoefficients,
                                size: geometry.size
                            )
                        }
                        
                        if viewModel.displayIdentifier == .frequencyResponse {
                            drawHwPlot(
                                synthesizedFrequencyResponse: viewModel.speechAnalyzer.synthesizedFrequencyResponse,
                                size: geometry.size
                            )
                        }
                        
                        if viewModel.displayIdentifier == .formant {
                            drawFormantPlot(
                                plottingF1: viewModel.plottingF1,
                                plottingF2: viewModel.plottingF2,
                                plottingF3: viewModel.plottingF3
                            )
                        }
                    }
                }
                
                // Formant labels and help button
                ZStack {
                    Button(action: {
                        viewModel.showHelp()
                    }) {
                        Text("?")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let f1 = viewModel.firstFormantLabel,
                       let f2 = viewModel.secondFormantLabel,
                       let f3 = viewModel.thirdFormantLabel,
                       let f4 = viewModel.fourthFormantLabel {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Formant 1:")
                                Text("Formant 3:")
                            }
                            VStack(alignment: .trailing) {
                                Text(f1)
                                Text(f3)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Formant 2:")
                                Text("Formant 4:")
                            }
                            VStack(alignment: .trailing) {
                                Text(f2)
                                Text(f4)
                            }
                        }
                    }
                }
                .frame(height: 50)
            }
            .padding()
        }
    }
    
    private var ipadMacConfig = IpadAndMacConfiguration(anchor: nil, arrowEdge: nil)
    
    private func actionSheetButtons() -> [ActionOverButton] {
        return [
            [ActionOverButton(
                title: "Microphone",
                type: .normal,
                action: { self.viewModel.microphoneSelected() }
            )],
            viewModel.soundFileBaseNames.map { basename in
                ActionOverButton(
                    title: basename,
                    type: .normal,
                    action: { self.viewModel.fileSelected(as: basename) }
                )
            },
            [ActionOverButton(
                title: nil,
                type: .cancel,
                action: nil
            )],
        ].flatMap { $0 }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FormantAnalyzerViewModel())
    }
}
