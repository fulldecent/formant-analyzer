//
//  ContentView.swift
//  Formant Analyzer SwiftUI
//
//  Created by William Entriken on 10.09.2020.
//  Copyright © 2020 William Entriken. All rights reserved.
//

import SwiftUI
import ActionOver

struct ContentView: View {
    
    @EnvironmentObject var viewModel: FormantAnalyzerViewModel
    @State private var showingActionSheet = false
    
    var body: some View {
        
        ZStack {
            Color(red: 255.0 / 255, green: 254.0 / 255, blue: 249.0 / 255)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    if (viewModel.speechIsFromMicrophone) {
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
                                title: "Audio Source",
                                message: "Select the audio source to analyze",
                                buttons: actionSheetButtons(),
                                ipadAndMacConfiguration: ipadMacConfig,
                                normalButtonColor: UIColor(red: 255.0 / 255, green: 103.0 / 255, blue: 97.0 / 255, alpha: 1)
                        )
                }
                
                Picker("Numbers", selection: $viewModel.displayIdentifier) {
                    
                    Text("Sig").tag(GraphingMode.signal)
                    Text("LPC").tag(GraphingMode.lpc)
                    Text("H(ω)").tag(GraphingMode.frequencyResponse)
                    Text("Frmnt").tag(GraphingMode.formant)
                    
                }
                .pickerStyle(SegmentedPickerStyle())
                
                ZStack {
                    Spacer()
                    
                    if viewModel.displayIdentifier == .signal && viewModel.speechAnalyzer.samples.count > 0{
                        VStack(spacing: 0) {
                            GeometryReader { geometry in
                                drawSignalPlot(plottableValues: self.viewModel.speechAnalyzer.downsampleToSamples(400).map{max(0,Double($0))},
                                               size: geometry.size,
                                               strongPartFirst: self.viewModel.speechAnalyzer.strongPart.first!,
                                               strongPartCount: self.viewModel.speechAnalyzer.strongPart.count,
                                               vowelPartFirst: self.viewModel.speechAnalyzer.vowelPart.first!,
                                               vowelPartCount: self.viewModel.speechAnalyzer.vowelPart.count,
                                               samplesCount: self.viewModel.speechAnalyzer.samples.count
                                )
                            }
                            GeometryReader { geometry in
                                drawSignalPlot(plottableValues: self.viewModel.speechAnalyzer.downsampleToSamples(400).map{max(0,Double($0))}.map({-$0}),
                                               size: geometry.size,
                                               strongPartFirst: self.viewModel.speechAnalyzer.strongPart.first!,
                                               strongPartCount: self.viewModel.speechAnalyzer.strongPart.count,
                                               vowelPartFirst: self.viewModel.speechAnalyzer.vowelPart.first!,
                                               vowelPartCount: self.viewModel.speechAnalyzer.vowelPart.count,
                                               samplesCount: self.viewModel.speechAnalyzer.samples.count
                                )
                            }
                        }
                    }
                    
                    if viewModel.displayIdentifier == .lpc {
                        GeometryReader { geometry in
                            drawLPCPlot(lpcCoefficients: self.viewModel.speechAnalyzer.estimatedLpcCoefficients,
                                        size: geometry.size)
                        }
                    }
                    
                    if viewModel.displayIdentifier == .frequencyResponse {
                        GeometryReader { geometry in
                            drawHwPlot(synthesizedFrequencyResponse: self.viewModel.speechAnalyzer.synthesizedFrequencyResponse,
                                        size: geometry.size)
                        }
                    }
                    
                    if viewModel.displayIdentifier == .formant {
                        drawFormantPlot(plottingF1: self.viewModel.plottingF1,
                        plottingF2: self.viewModel.plottingF2,
                        plottingF3: self.viewModel.plottingF3)
                    }

                }
                
                ZStack {
                    
                    Button(action: {
                        self.viewModel.showHelp()
                    }) {
                        Text("?")
                    }
                    
                    if viewModel.firstFormantLabel != nil
                        && viewModel.secondFormantLabel != nil
                        && viewModel.thirdFormantLabel != nil
                        && viewModel.fourthFormantLabel != nil{
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Formant 1:")
                                Text("Formant 3:")
                            }
                            VStack(alignment: .trailing) {
                                Text(viewModel.firstFormantLabel!)
                                Text(viewModel.thirdFormantLabel!)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Formant 2:")
                                Text("Formant 4:")
                            }
                            VStack(alignment: .trailing) {
                                Text(viewModel.secondFormantLabel!)
                                Text(viewModel.fourthFormantLabel!)
                            }
                        }
                    }
                }
                .frame(height:50)

                
            }
            .padding()

            
            
            
        }
    }
    
    private var ipadMacConfig = {
        IpadAndMacConfiguration(anchor: nil, arrowEdge: nil)
    }()
    
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
        ].reduce([], +)
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        .environmentObject(FormantAnalyzerViewModel())
    }
}
