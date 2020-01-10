//
//  ViewController.swift
//  FormantPlotter
//
//  Created by William Entriken on 1/21/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import FSLineChart
import FDSoundActivatedRecorder
import SafariServices

enum GraphingMode: Int {
    case signal
    case lpc
    case frequencyResponse
    case formant
}

class FirstViewController: UIViewController {
    // Top row
    @IBOutlet var indicatorImageView: UIImageView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet weak var inputSelector: UIButton!
    // Second row
    @IBOutlet var graphingMode: UISegmentedControl!
    // Third row
    @IBOutlet var formantPlot: FormantPlotView!
    @IBOutlet var lineChartTopHalf: FSLineChart!
    @IBOutlet var lineChartBottomHalf: FSLineChart!
    @IBOutlet var lineChartFull: FSLineChart!
    // Fourth row
    @IBOutlet var firstFormantLabel: UILabel!
    @IBOutlet var secondFormantLabel: UILabel!
    @IBOutlet var thirdFormantLabel: UILabel!
    @IBOutlet var fourthFormantLabel: UILabel!
        
    var displayIdentifier: GraphingMode = .signal
    
    lazy var soundActivatedRecorder: FDSoundActivatedRecorder = {
        let retval = FDSoundActivatedRecorder()
        retval.delegate = self
        return retval
    }()
    
    /// Whether we are processing live speech or stored samples.
    var speechIsFromMicrophone = true
    
    /// Which stored file (1 out of 7) is being processed
    var soundFileIdentifier = 0
    
    /// Array of names of 7 stored sound files.
    var soundFileBaseNames = ["arm", "beat", "bid", "calm", "cat", "four", "who"]
    
    var speechAnalyzer = SpeechAnalyzer(int16Samples: Data(), withFrequency: 44100)
    
    var speechData = Data()
    
    func showPlotForDisplayIdentifier(_ displayIdentifier: GraphingMode, withAnalyzer analyzer: SpeechAnalyzer) {
        self.formantPlot.isHidden = true
        self.lineChartTopHalf.isHidden = true
        self.lineChartBottomHalf.isHidden = true
        self.lineChartFull.isHidden = true
        
        switch displayIdentifier {
        case .signal:
            self.drawSignalPlot()
            self.lineChartTopHalf.isHidden = false
            self.lineChartBottomHalf.isHidden = false
        case .lpc:
            self.drawLPCPlot()
            self.lineChartFull.isHidden = false
        case .frequencyResponse:
            self.drawHwPlot()
            self.lineChartFull.isHidden = false
        case .formant:
            self.formantPlot.formants = self.speechAnalyzer.formants
            self.formantPlot.setNeedsDisplay()
            self.formantPlot.isHidden = false
        }
    }
    
    //TODO: Should be a separate view class
    func drawSignalPlot() {
        guard speechAnalyzer.samples.count > 0 else {
            return
        }
        
        let plottableValuesHigh: [Double] = self.speechAnalyzer.downsampleToSamples(400).map{max(0,Double($0))}
        let plottableValuesLow: [Double] = plottableValuesHigh.map({-$0})
        self.lineChartTopHalf.drawInnerGrid = false
        self.lineChartTopHalf.axisLineWidth = 0
        self.lineChartTopHalf.margin = 0
        self.lineChartTopHalf.axisWidth = self.lineChartTopHalf.frame.size.width
        self.lineChartTopHalf.axisHeight = self.lineChartTopHalf.frame.size.height
        self.lineChartTopHalf.backgroundColor = UIColor.clear
        self.lineChartTopHalf.fillColor = UIColor.blue
        self.lineChartTopHalf.clearData()
        self.lineChartTopHalf.setChartData(plottableValuesHigh)
        self.lineChartBottomHalf.drawInnerGrid = false
        self.lineChartBottomHalf.axisLineWidth = 0
        self.lineChartBottomHalf.margin = 0
        self.lineChartBottomHalf.axisWidth = self.lineChartTopHalf.frame.size.width
        self.lineChartBottomHalf.axisHeight = self.lineChartTopHalf.frame.size.height
        self.lineChartBottomHalf.backgroundColor = UIColor.clear
        self.lineChartBottomHalf.fillColor = UIColor.blue
        self.lineChartBottomHalf.clearData()
        self.lineChartBottomHalf.setChartData(plottableValuesLow)
        
        self.lineChartTopHalf.subviews.forEach({$0.removeFromSuperview()})
        self.lineChartBottomHalf.subviews.forEach({$0.removeFromSuperview()})
        
        let strongRect = CGRect(
            x: CGFloat(self.lineChartTopHalf.frame.size.width) * CGFloat(self.speechAnalyzer.strongPart.first!) / CGFloat(self.speechAnalyzer.samples.count),
            y: 0,
            width: CGFloat(self.lineChartTopHalf.frame.size.width) * CGFloat(self.speechAnalyzer.strongPart.count) / CGFloat(self.speechAnalyzer.samples.count),
            height: self.lineChartTopHalf.frame.size.height * 2)
        let strongBox = UIView(frame: strongRect)
        strongBox.backgroundColor = UIColor(hue: 60.0/255.0, saturation: 180.0/255.0, brightness: 92.0/255.0, alpha: 0.2)
        self.lineChartTopHalf.insertSubview(strongBox, at: 0)

        let vowelRect = CGRect(
            x: CGFloat(self.lineChartTopHalf.frame.size.width) * CGFloat(self.speechAnalyzer.vowelPart.first!) / CGFloat(self.speechAnalyzer.samples.count),
            y: self.lineChartTopHalf.frame.size.height * 0.05,
            width: CGFloat(self.lineChartTopHalf.frame.size.width) * CGFloat(self.speechAnalyzer.vowelPart.count) / CGFloat(self.speechAnalyzer.samples.count),
            height: self.lineChartTopHalf.frame.size.height * 1.9)
        let vowelBox = UIView(frame: vowelRect)
        vowelBox.backgroundColor = UIColor(hue: 130.0/255.0, saturation: 180.0/255.0, brightness: 92.0/255.0, alpha: 0.2)
        self.lineChartTopHalf.insertSubview(vowelBox, at: 0)
    }
    
    //TODO: Should be a separate view class
    func drawLPCPlot() {
        // Index label properties
        self.lineChartFull.labelForIndex = {
            (item: UInt) -> String in
            return "\(Int(item))"
        }
        // Value label properties
        self.lineChartFull.labelForValue = {
            (value: CGFloat) -> String in
            return String(format: "%.02f", value)
        }
        self.lineChartFull.valueLabelPosition = .left
        // Number of visible step in the chart
        self.lineChartFull.verticalGridStep = 3
        self.lineChartFull.horizontalGridStep = 20
        // Margin of the chart
        self.lineChartFull.margin = 40
        self.lineChartFull.axisWidth = self.lineChartFull.frame.size.width - 2 * self.lineChartFull.margin
        self.lineChartFull.axisHeight = self.lineChartFull.frame.size.height - 2 * self.lineChartFull.margin
        // Decoration parameters, let you pick the color of the line as well as the color of the axis
        self.lineChartFull.axisLineWidth = 1
        // Chart parameters
        self.lineChartFull.color = UIColor.black
        self.lineChartFull.fillColor = UIColor.blue
        self.lineChartFull.backgroundColor = UIColor.clear
        // Grid parameters
        self.lineChartFull.drawInnerGrid = true
        let lpcCoefficients: [Double] = self.speechAnalyzer.estimatedLpcCoefficients
        self.lineChartFull.clearData()
        self.lineChartFull.setChartData(lpcCoefficients)
    }
    
    //TODO: Should be a separate view class
    func drawHwPlot() {
        // Index label properties
        self.lineChartFull.labelForIndex = {
            (item: UInt) -> String in
            return String(format: "%.0f kHz", Double(item) / 60)
        }
        // Value label properties
        self.lineChartFull.labelForValue = {
            (value: CGFloat) -> String in
            return String(format: "%.02f", value)
        }
        self.lineChartFull.valueLabelPosition = .left
        // Number of visible steps in the chart
        self.lineChartFull.verticalGridStep = 3
        self.lineChartFull.horizontalGridStep = 5
        // Margin of the chart
        self.lineChartFull.margin = 40
        self.lineChartFull.axisWidth = self.lineChartFull.frame.size.width - 2 * self.lineChartFull.margin
        self.lineChartFull.axisHeight = self.lineChartFull.frame.size.height - 2 * self.lineChartFull.margin
        // Decoration parameters, let you pick the color of the line as well as the color of the axis
        self.lineChartFull.axisLineWidth = 1
        // Chart parameters
        self.lineChartFull.color = UIColor.black
        self.lineChartFull.fillColor = UIColor.blue
        self.lineChartFull.backgroundColor = UIColor.clear
        // Grid parameters
        self.lineChartFull.drawInnerGrid = true
        let synthesizedFrequencyResponse: [Double] = self.speechAnalyzer.synthesizedFrequencyResponse
        self.lineChartFull.clearData()
        self.lineChartFull.setChartData(synthesizedFrequencyResponse)
    }
    
    @IBAction func graphingModeChanged(_ sender: UISegmentedControl) {
        self.displayIdentifier = GraphingMode(rawValue: sender.selectedSegmentIndex)!
        self.showPlotForDisplayIdentifier(self.displayIdentifier, withAnalyzer: self.speechAnalyzer)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: {(context: UIViewControllerTransitionCoordinatorContext) -> Void in
            self.showPlotForDisplayIdentifier(self.displayIdentifier, withAnalyzer: self.speechAnalyzer)
            }, completion: {(context: UIViewControllerTransitionCoordinatorContext) -> Void in
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func displayFormantFrequencies() {
        let formants: [Double] = self.speechAnalyzer.formants
        let firstFLabel = String(format: "Formant 1:%5.0f", formants[0])
        self.firstFormantLabel.text = firstFLabel
        let secondFLabel = String(format: "Formant 2:%5.0f", formants[1])
        self.secondFormantLabel.text = secondFLabel
        let thirdFLabel = String(format: "Formant 3:%5.0f", formants[2])
        self.thirdFormantLabel.text = thirdFLabel
        let fourthFLabel = String(format: "Formant 4:%5.0f", formants[3])
        self.fourthFormantLabel.text = fourthFLabel
    }

    func processRawBuffer() {
        let fileURL = Bundle.main.url(forResource: self.soundFileBaseNames[self.soundFileIdentifier], withExtension: "raw")!
        NSLog("Processing saved file %@", self.soundFileBaseNames[self.soundFileIdentifier])
        speechData = try! Data(contentsOf: fileURL)
        self.speechAnalyzer = SpeechAnalyzer(int16Samples: speechData, withFrequency: 44100)
        displayFormantFrequencies()
        self.showPlotForDisplayIdentifier(self.displayIdentifier, withAnalyzer: self.speechAnalyzer)
    }
    
    /// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.indicatorImageView.image = UIImage(named: "green_light.png")
        self.inputSelector.setTitle("Microphone", for: UIControl.State())
        self.speechIsFromMicrophone = true
        self.indicatorImageView.isHidden = false
        self.statusLabel.text = "Listening ..."
        _ = try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: AVAudioSession.Mode.default)
        self.soundActivatedRecorder.startListening()
    }
    
    @IBAction func showHelp() {
        let url = URL(string: "https://fulldecent.github.io/formant-analyzer/")!

        if #available(iOS 9.0, *) {
            let svc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
            svc.delegate = self
            self.present(svc, animated: true, completion: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func showInputSelectSheet(_ sender: UIButton) {
        let alert: UIAlertController = UIAlertController(title: "Audio source", message: "Select the audio soucre to analyze", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Microphone", style: .default, handler: {
            (action: UIAlertAction) -> Void in
            self.inputSelector.setTitle("Microphone", for: UIControl.State())
            self.speechIsFromMicrophone = true
            self.indicatorImageView.isHidden = false
            self.statusLabel.text = "Waiting ..."
            self.soundActivatedRecorder.startListening()
        }))
        for basename: String in self.soundFileBaseNames {
            alert.addAction(UIAlertAction(title: basename, style: .default, handler: {
                (action: UIAlertAction) -> Void in
                self.soundActivatedRecorder.abort()
                self.inputSelector.setTitle("File", for: UIControl.State())
                self.speechIsFromMicrophone = false
                self.indicatorImageView.isHidden = true
                self.soundFileIdentifier = self.soundFileBaseNames.firstIndex(of: basename)!
                self.statusLabel.text = self.soundFileBaseNames[self.soundFileIdentifier]
                self.processRawBuffer()
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
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

extension FirstViewController: FDSoundActivatedRecorderDelegate {
    /// A recording was successfully captured
    public func soundActivatedRecorderDidFinishRecording(recorder: FDSoundActivatedRecorder, andSaved file: NSURL) {
    }

    func soundActivatedRecorderDidStartRecording(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async(execute: {
            NSLog("STARTED RECORDING")
            self.indicatorImageView.image = UIImage(named: "blue_light.png")
            self.statusLabel.text = "Capturing sound"
        })
    }

    func soundActivatedRecorderDidFinishRecording(_ recorder: FDSoundActivatedRecorder, andSaved file: URL) {
        DispatchQueue.main.async(execute: {
            NSLog("STOPPED RECORDING")
            self.indicatorImageView.image = UIImage(named: "red_light.png")
            self.statusLabel.text = "Processing sound"
            self.speechData = self.readSoundFileSamples(file)
            self.speechAnalyzer = SpeechAnalyzer(int16Samples: self.speechData, withFrequency: 44100)
            self.displayFormantFrequencies()
            self.showPlotForDisplayIdentifier(self.displayIdentifier, withAnalyzer: self.speechAnalyzer)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(NSEC_PER_SEC) / 2) / Double(NSEC_PER_SEC), execute: {
                self.indicatorImageView.image = UIImage(named: "green_light.png")
                self.statusLabel.text = "Listening ..."
                self.soundActivatedRecorder.startListening()
            })
        })
    }
    
    func soundActivatedRecorderDidAbort(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async(execute: {
            NSLog("STOPPED RECORDING")
            self.indicatorImageView.image = UIImage(named: "red_light.png")
            self.statusLabel.text = "Retrying ..."
            if self.speechIsFromMicrophone {
                self.soundActivatedRecorder.startListening()
            }
        })
    }
    
    func soundActivatedRecorderDidTimeOut(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async(execute: {
            NSLog("STOPPED RECORDING")
            self.indicatorImageView.image = UIImage(named: "red_light.png")
            self.statusLabel.text = "Retrying ..."
            if self.speechIsFromMicrophone {
                self.soundActivatedRecorder.startListening()
            }
        })
    }
}

@available(iOS 9.0, *)
extension FirstViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
