//
//  ViewModel.swift
//  Formant Analyzer
//
//  Created by William Entriken on 11.09.2020.
//  Copyright © 2020 William Entriken. All rights reserved.
//



import Foundation
import AVFoundation
import FDSoundActivatedRecorder
import FSLineChart

enum GraphingMode: Int {
    case signal
    case lpc
    case frequencyResponse
    case formant
}

// Classes are easy to share
class FormantAnalyzerViewModel: ObservableObject {
    
    // Top row
    @Published var indicatorImage: String = "green_light"
    @Published var statusLabel: String = "Listening ..."
    @Published var inputSelector: String = "Microphone"

    // Fourth row
    @Published var firstFormantLabel: String?
    @Published var secondFormantLabel: String?
    @Published var thirdFormantLabel: String?
    @Published var fourthFormantLabel: String?
    
    @Published var displayIdentifier: GraphingMode = .signal
    
    var plottingF1: Double?
    var plottingF2: Double?
    var plottingF3: Double?
    
    lazy var soundActivatedRecorder: FDSoundActivatedRecorder = {
        let retval = FDSoundActivatedRecorder()
        retval.delegate = self
        return retval
    }()
    
    /// Whether we are processing live speech or stored samples.
    @Published var speechIsFromMicrophone = true
    
    /// Which stored file (1 out of 7) is being processed
    var soundFileIdentifier = 0
    
    /// Array of names of 7 stored sound files.
    let soundFileBaseNames = ["arm", "beat", "bid", "calm", "cat", "four", "who"]

    var speechAnalyzer = SpeechAnalyzer(int16Samples: Data(), withFrequency: 44100)
    
    var speechData = Data()

    func displayFormantFrequencies() {
        let formants: [Double] = self.speechAnalyzer.formants
        firstFormantLabel = String(format: "%5.0f", formants[0])
        secondFormantLabel = String(format: "%5.0f", formants[1])
        thirdFormantLabel = String(format: "%5.0f", formants[2])
        fourthFormantLabel = String(format: "%5.0f", formants[3])
        
        // Plotting Formants
        // Choose the two formants we want to plot
        let plottingFmtX = formants[0]
        let plottingFmtY = formants[1]
        
        // Translate from formant in Hz to x/y position as a portion of plot image
        // Need to consider scale of plot image and make it line up
        plottingF1 = 0.103 + (plottingFmtX - 0) / 1200 * (0.953 - 0.103)
        let logPart = log(plottingFmtY) / log(2.0) - log(500.0) / log(2.0)
        plottingF2 = (1.00 - 0.134) - logPart * (0.414 - 0.134)
        
        // If `f2` is too close to `f1`, use `f3` for vertical axis.
        if formants[1] < 1.6 * formants[0] {
            let plottingFmtY = formants[2]
            let logPart = log(plottingFmtY) / log(2.0) - log(500.0) / log(2.0)
            plottingF3 = (1.00 - 0.134) - logPart * (0.414 - 0.134)
        } else {
            plottingF3 = nil
        }
    }

    func processRawBuffer() {
        let fileURL = Bundle.main.url(forResource: self.soundFileBaseNames[self.soundFileIdentifier], withExtension: "raw")!
        NSLog("Processing saved file %@", self.soundFileBaseNames[self.soundFileIdentifier])
        speechData = try! Data(contentsOf: fileURL)
        self.speechAnalyzer = SpeechAnalyzer(int16Samples: speechData, withFrequency: 44100)
        displayFormantFrequencies()
    }
    
    
    init() {
        _ = try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: AVAudioSession.Mode.default)
        self.soundActivatedRecorder.startListening()
    }
    
    
    func showHelp() {
        if let url = URL(string: "https://fulldecent.github.io/formant-analyzer/") {
            UIApplication.shared.open(url)
        }
    }
    
    func microphoneSelected() {
        inputSelector = "Microphone"
        speechIsFromMicrophone = true
        statusLabel = "Waiting ..."
        soundActivatedRecorder.startListening()
    }
    func fileSelected(as basename: String) {
        soundActivatedRecorder.abort()
        inputSelector = "File"
        speechIsFromMicrophone = false
        soundFileIdentifier = soundFileBaseNames.firstIndex(of: basename)!
        statusLabel = basename
        processRawBuffer()
    }
    
    /// Get raw PCM data from the track
    func readSoundFileSamples(_ assetURL: URL) -> Data {
        let retval = NSMutableData()
        let asset = AVURLAsset(url: assetURL)
        let track = asset.tracks[0]
        let reader = try! AVAssetReader(asset: asset)
        let settings: [String: NSNumber] = [
            AVFormatIDKey: NSNumber(integerLiteral: Int(kAudioFormatLinearPCM)),
            AVSampleRateKey: 16000.0,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: 0,
            AVLinearPCMIsFloatKey: 0,
            AVLinearPCMIsBigEndianKey: 0
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        reader.add(output)
        reader.startReading()
        // read the samples from the asset and append them subsequently
        while reader.status != .completed {
            guard let buffer = output.copyNextSampleBuffer() else {
                continue
            }
            let blockBuffer = CMSampleBufferGetDataBuffer(buffer)!
            let size = CMBlockBufferGetDataLength(blockBuffer)
            let outBytes = NSMutableData(length: size)!
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: size, destination: outBytes.mutableBytes)
            CMSampleBufferInvalidate(buffer)
            retval.append(outBytes as Data)
        }
        return retval as Data
    }
}


extension FormantAnalyzerViewModel: FDSoundActivatedRecorderDelegate {
    /// A recording was successfully captured
    public func soundActivatedRecorderDidFinishRecording(recorder: FDSoundActivatedRecorder, andSaved file: NSURL) {
    }

    func soundActivatedRecorderDidStartRecording(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async(execute: {
            NSLog("STARTED RECORDING")
            self.indicatorImage = "blue_light"
            self.statusLabel = "Capturing sound"
        })
    }

    func soundActivatedRecorderDidFinishRecording(_ recorder: FDSoundActivatedRecorder, andSaved file: URL) {
        DispatchQueue.main.async(execute: {
            NSLog("STOPPED RECORDING")
            self.indicatorImage = "red_light"
            self.statusLabel = "Processing sound"
            self.speechData = self.readSoundFileSamples(file)
            self.speechAnalyzer = SpeechAnalyzer(int16Samples: self.speechData, withFrequency: 44100)
            self.displayFormantFrequencies()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(NSEC_PER_SEC) / 2) / Double(NSEC_PER_SEC), execute: {
                self.indicatorImage = "green_light"
                self.statusLabel = "Listening ..."
                self.soundActivatedRecorder.startListening()
            })
        })
    }
    
    func soundActivatedRecorderDidAbort(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async(execute: {
            NSLog("STOPPED RECORDING")
            self.indicatorImage = "red_light"
            
            if self.speechIsFromMicrophone {
                self.statusLabel = "Retrying ..."
                self.soundActivatedRecorder.startListening()
            }
        })
    }
    
    func soundActivatedRecorderDidTimeOut(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async(execute: {
            NSLog("STOPPED RECORDING")
            self.indicatorImage = "red_light"
            
            if self.speechIsFromMicrophone {
                self.statusLabel = "Retrying ..."
                self.soundActivatedRecorder.startListening()
            }
        })
    }
}
