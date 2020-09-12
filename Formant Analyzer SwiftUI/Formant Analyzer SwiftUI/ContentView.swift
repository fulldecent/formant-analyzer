//
//  ContentView.swift
//  Formant Analyzer SwiftUI
//
//  Created by William Entriken on 10.09.2020.
//  Copyright © 2020 William Entriken. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var viewModel: FormantAnalyzerViewModel
    @State private var showingActionSheet = false
    
    var body: some View {
        
        ZStack {
            Color(red: 253.0 / 255, green: 239.0 / 255, blue: 238.0 / 255)
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
                    }) {
                        Text(viewModel.inputSelector)
                    }
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
                            VStack {
                                Text("Formant 1:")
                                Text("Formant 3:")
                            }
                            VStack {
                                Text(viewModel.firstFormantLabel!)
                                Text(viewModel.thirdFormantLabel!)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("Formant 2:")
                                Text("Formant 4:")
                            }
                            VStack {
                                Text(viewModel.secondFormantLabel!)
                                Text(viewModel.fourthFormantLabel!)
                            }
                        }
                    }
                }
                .frame(height:50)
                
            }.padding()
            
            
            
        }.actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(title: Text("Audio Source"), message: Text("Select the audio source to analyze"), buttons: actionSheetButtons())
        }
    }
    
    func actionSheetButtons() -> [ActionSheet.Button] {
        
        [
            [ActionSheet.Button.default(Text("Microphone")) { self.viewModel.microphoneSelected() }],
            viewModel.soundFileBaseNames.map { basename in
                ActionSheet.Button.default(Text(basename)) { self.viewModel.fileSelected(as: basename) }
            },
            [ActionSheet.Button.cancel()]
            ].reduce([], +)
    }
    
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        .environmentObject(FormantAnalyzerViewModel())
    }
}
