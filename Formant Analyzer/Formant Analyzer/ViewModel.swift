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
import UIKit

/// Modes for displaying different types of graphs in the formant analyzer.
enum GraphingMode: Int {
    case signal
    case lpc
    case frequencyResponse
    case formant
}

/// Manages the state and logic for the formant analyzer, including audio recording and formant analysis.
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
    
    private lazy var soundActivatedRecorder: FDSoundActivatedRecorder = {
        let recorder = FDSoundActivatedRecorder()
        recorder.delegate = self
        return recorder
    }()
    
    /// Whether audio input is from the microphone or stored files.
    @Published var speechIsFromMicrophone = true
    
    /// Index of the stored sound file being processed (0 to 6).
    private var soundFileIdentifier = 0
    
    /// Names of the stored sound files.
    let soundFileBaseNames = ["arm", "beat", "bid", "calm", "cat", "four", "who"]

    var speechAnalyzer = SpeechAnalyzer(int16Samples: Data(), withFrequency: 44100)
    private var speechData = Data()
    
    /// Updates the formant frequency labels and plotting coordinates.
    private func displayFormantFrequencies() {
        let formants: [Double] = speechAnalyzer.formants
        firstFormantLabel = String(format: "%5.0f", formants[0])
        secondFormantLabel = String(format: "%5.0f", formants[1])
        thirdFormantLabel = String(format: "%5.0f", formants[2])
        fourthFormantLabel = String(format: "%5.0f", formants[3])
        
        // Calculate plotting coordinates for formants
        let plottingFmtX = formants[0]
        let plottingFmtY = formants[1]
        
        // Map formant frequencies to plot coordinates
        plottingF1 = 0.103 + (plottingFmtX - 0) / 1200 * (0.953 - 0.103)
        let logPart = log(plottingFmtY) / log(2.0) - log(500.0) / log(2.0)
        plottingF2 = (1.00 - 0.134) - logPart * (0.414 - 0.134)
        
        // Use third formant for vertical axis if second is too close to first
        if formants[1] < 1.6 * formants[0] {
            let plottingFmtY = formants[2]
            let logPart = log(plottingFmtY) / log(2.0) - log(500.0) / log(2.0)
            plottingF3 = (1.00 - 0.134) - logPart * (0.414 - 0.134)
        } else {
            plottingF3 = nil
        }
    }
    
    /// Processes a stored raw audio file.
    private func processRawBuffer() {
        guard let fileURL = Bundle.main.url(forResource: soundFileBaseNames[soundFileIdentifier], withExtension: "raw") else {
            NSLog("Failed to load sound file: %@", soundFileBaseNames[soundFileIdentifier] as NSString)
            return
        }
        NSLog("Processing saved file: %@", soundFileBaseNames[soundFileIdentifier] as NSString)
        do {
            speechData = try Data(contentsOf: fileURL)
            speechAnalyzer = SpeechAnalyzer(int16Samples: speechData, withFrequency: 44100)
            displayFormantFrequencies()
        } catch {
            NSLog("Failed to process sound file: \(error)")
        }
    }
    
    /// Initializes the view model and starts audio listening.
    init() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else {
                NSLog("Microphone permission denied")
                return
            }
            DispatchQueue.main.async {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    self.soundActivatedRecorder.startListening()
                } catch {
                    NSLog("Failed to set up audio session: \(error)")
                }
            }
        }
    }
    
    /// Opens the help webpage in the default browser.
    func showHelp() {
        if let url = URL(string: "https://fulldecent.github.io/formant-analyzer/") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    /// Configures the app to use microphone input.
    func microphoneSelected() {
        inputSelector = "Microphone"
        speechIsFromMicrophone = true
        statusLabel = "Waiting ..."
        soundActivatedRecorder.startListening()
    }
    
    /// Configures the app to process a stored sound file.
    /// - Parameter basename: The base name of the sound file.
    func fileSelected(as basename: String) {
        guard let index = soundFileBaseNames.firstIndex(of: basename) else {
            NSLog("Invalid sound file: %@", basename as NSString)
            return
        }
        soundActivatedRecorder.abort()
        inputSelector = "File"
        speechIsFromMicrophone = false
        soundFileIdentifier = index
        statusLabel = basename
        processRawBuffer()
    }
    
    /// Reads raw PCM data from an audio file.
    /// - Parameter assetURL: The URL of the audio file.
    /// - Returns: The PCM data.
    func readSoundFileSamples(_ assetURL: URL) -> Data {
        let asset = AVURLAsset(url: assetURL)
        guard let track = asset.tracks.first else {
            NSLog("No audio track found in file: \(assetURL)")
            return Data()
        }
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        let reader: AVAssetReader
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            NSLog("Failed to create asset reader: \(error)")
            return Data()
        }
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        reader.add(output)
        reader.startReading()
        
        var data = Data()
        while reader.status == .reading {
            guard let buffer = output.copyNextSampleBuffer(),
                  let blockBuffer = CMSampleBufferGetDataBuffer(buffer) else {
                continue
            }
            let size = CMBlockBufferGetDataLength(blockBuffer)
            var bufferData = Data(repeating: 0, count: size)
            let copyStatus = bufferData.withUnsafeMutableBytes { ptr -> OSStatus in
                CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: size, destination: ptr.baseAddress!)
            }
            if copyStatus != noErr {
                NSLog("Error copying block buffer data: \(copyStatus)")
                continue
            }
            data.append(bufferData)
        }
        return data
    }
}

extension FormantAnalyzerViewModel: FDSoundActivatedRecorderDelegate {
    /// Called when the recorder starts capturing audio.
    func soundActivatedRecorderDidStartRecording(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async {
            NSLog("Started recording")
            self.indicatorImage = "blue_light"
            self.statusLabel = "Capturing sound"
        }
    }
    
    /// Called when the recorder finishes capturing audio and saves the file.
    func soundActivatedRecorderDidFinishRecording(_ recorder: FDSoundActivatedRecorder, andSaved file: URL) {
        DispatchQueue.main.async {
            NSLog("Stopped recording")
            self.indicatorImage = "red_light"
            self.statusLabel = "Processing sound"
            self.speechData = self.readSoundFileSamples(file)
            self.speechAnalyzer = SpeechAnalyzer(int16Samples: self.speechData, withFrequency: 44100)
            self.displayFormantFrequencies()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.indicatorImage = "green_light"
                self.statusLabel = "Listening ..."
                self.soundActivatedRecorder.startListening()
            }
        }
    }
    
    /// Called when the recorder aborts due to an error.
    func soundActivatedRecorderDidAbort(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async {
            NSLog("Stopped recording")
            self.indicatorImage = "red_light"
            if self.speechIsFromMicrophone {
                self.statusLabel = "Retrying ..."
                self.soundActivatedRecorder.startListening()
            }
        }
    }
    
    /// Called when the recorder times out.
    func soundActivatedRecorderDidTimeOut(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async {
            NSLog("Stopped recording")
            self.indicatorImage = "red_light"
            if self.speechIsFromMicrophone {
                self.statusLabel = "Retrying ..."
                self.soundActivatedRecorder.startListening()
            }
        }
    }
}
