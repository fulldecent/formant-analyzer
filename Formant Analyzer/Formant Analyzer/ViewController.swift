//
//  ViewController.swift
//  FormantPlotter
//
//  Created by William Entriken on 1/21/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import FSLineChart
import FDSoundActivatedRecorder
import TOWebViewController

enum GraphingMode: Int {
    case Signal
    case LPC
    case FrequencyResponse
    case Formant
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
        
    var displayIdentifier: GraphingMode = .Signal
    
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
    
    var speechAnalyzer = SpeechAnalyzer(int16Samples: NSData(), withFrequency: 44100)
    
    var speechData = NSData()
    
    func showPlotForDisplayIdentifier(displayIdentifier: GraphingMode, withAnalyzer analyzer: SpeechAnalyzer) {
        displayFormantFrequencies()
        
        //TODO: fix UGLIEST HACK
        let newChart: FSLineChart = FSLineChart(frame: self.lineChartFull.frame)
        self.lineChartFull.removeFromSuperview()
        self.view!.addSubview(newChart)
        self.lineChartFull = newChart
        self.formantPlot.hidden = true
        
        //TODO: these should each be separate view classes
        switch displayIdentifier {
        case .Signal:
            self.drawSignalPlot()
        case .LPC:
            self.drawLPCPlot()
        case .FrequencyResponse:
            self.drawHwPlot()
        case .Formant:
            //TODO: TEMP HACK
            self.formantPlot.formants = self.speechAnalyzer.formants //TODO this linke crashes
            self.formantPlot.hidden = false
            self.lineChartTopHalf.hidden = true
            self.lineChartBottomHalf.hidden = true
            self.lineChartFull.hidden = true
            self.formantPlot.setNeedsDisplay()
        }
    }
    
    func drawSignalPlot() {
        let plottableValuesHigh: [Double] = self.speechAnalyzer.downsampleToSamples(400).map{max(0,Double($0))}
        let plottableValuesLow: [Double] = plottableValuesHigh.map({-$0})
        self.lineChartFull.hidden = true
        self.lineChartTopHalf.hidden = false
        self.lineChartTopHalf.drawInnerGrid = false
        self.lineChartTopHalf.axisLineWidth = 0
        self.lineChartTopHalf.margin = 0
        self.lineChartTopHalf.axisWidth = self.lineChartTopHalf.frame.size.width
        self.lineChartTopHalf.axisHeight = self.lineChartTopHalf.frame.size.height
        self.lineChartTopHalf.backgroundColor = UIColor.clearColor()
        self.lineChartTopHalf.fillColor = UIColor.blueColor()
        self.lineChartTopHalf.clearChartData()
        self.lineChartTopHalf.setChartData(plottableValuesHigh)
        self.lineChartBottomHalf.hidden = false
        self.lineChartBottomHalf.drawInnerGrid = false
        self.lineChartBottomHalf.axisLineWidth = 0
        self.lineChartBottomHalf.margin = 0
        self.lineChartBottomHalf.axisWidth = self.lineChartTopHalf.frame.size.width
        self.lineChartBottomHalf.axisHeight = self.lineChartTopHalf.frame.size.height
        self.lineChartBottomHalf.backgroundColor = UIColor.clearColor()
        self.lineChartBottomHalf.fillColor = UIColor.blueColor()
        self.lineChartBottomHalf.clearChartData()
        self.lineChartBottomHalf.setChartData(plottableValuesLow)
        
        self.lineChartTopHalf.subviews.forEach({$0.removeFromSuperview()})
        
        let strongRect = CGRect(
            x: CGFloat(self.lineChartTopHalf.frame.size.width) * CGFloat(self.speechAnalyzer.strongPart.first!) / CGFloat(self.speechAnalyzer.samples.count),
            y: 0,
            width: CGFloat(self.lineChartTopHalf.frame.size.width) * CGFloat(self.speechAnalyzer.strongPart.count) / CGFloat(self.speechAnalyzer.samples.count),
            height: self.lineChartTopHalf.frame.size.height * 2)
        let strongBox = UIView(frame: strongRect)
        strongBox.backgroundColor = UIColor(hue: 60.0/255.0, saturation: 180.0/255.0, brightness: 92.0/255.0, alpha: 0.2)
        self.lineChartTopHalf.insertSubview(strongBox, atIndex: 0)

        let vowelRect = CGRect(
            x: CGFloat(self.lineChartTopHalf.frame.size.width) * CGFloat(self.speechAnalyzer.vowelPart.first!) / CGFloat(self.speechAnalyzer.samples.count),
            y: self.lineChartTopHalf.frame.size.height * 0.05,
            width: CGFloat(self.lineChartTopHalf.frame.size.width) * CGFloat(self.speechAnalyzer.vowelPart.count) / CGFloat(self.speechAnalyzer.samples.count),
            height: self.lineChartTopHalf.frame.size.height * 1.9)
        let vowelBox = UIView(frame: vowelRect)
        vowelBox.backgroundColor = UIColor(hue: 130.0/255.0, saturation: 180.0/255.0, brightness: 92.0/255.0, alpha: 0.2)
        self.lineChartTopHalf.insertSubview(vowelBox, atIndex: 0)
    }
    
    func drawLPCPlot() {
        self.formantPlot.hidden = true
        self.lineChartTopHalf.hidden = true
        self.lineChartBottomHalf.hidden = true
        self.lineChartFull.hidden = false
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
        self.lineChartFull.valueLabelPosition = .Left
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
        self.lineChartFull.color = UIColor.blackColor()
        self.lineChartFull.fillColor = UIColor.blueColor()
        self.lineChartFull.backgroundColor = UIColor.clearColor()
        // Grid parameters
        self.lineChartFull.drawInnerGrid = true
        let lpcCoefficients: [Double] = self.speechAnalyzer.estimatedLpcCoefficients
        self.lineChartFull.clearChartData()
        self.lineChartFull.setChartData(lpcCoefficients)
    }
    
    func drawHwPlot() {
        self.formantPlot.hidden = true
        self.lineChartTopHalf.hidden = true
        self.lineChartBottomHalf.hidden = true
        self.lineChartFull.hidden = false
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
        self.lineChartFull.valueLabelPosition = .Left
        // Number of visible step in the chart
        self.lineChartFull.verticalGridStep = 3
        self.lineChartFull.horizontalGridStep = 5
        // Margin of the chart
        self.lineChartFull.margin = 40
        self.lineChartFull.axisWidth = self.lineChartFull.frame.size.width - 2 * self.lineChartFull.margin
        self.lineChartFull.axisHeight = self.lineChartFull.frame.size.height - 2 * self.lineChartFull.margin
        // Decoration parameters, let you pick the color of the line as well as the color of the axis
        self.lineChartFull.axisLineWidth = 1
        // Chart parameters
        self.lineChartFull.color = UIColor.blackColor()
        self.lineChartFull.fillColor = UIColor.blueColor()
        self.lineChartFull.backgroundColor = UIColor.clearColor()
        // Grid parameters
        self.lineChartFull.drawInnerGrid = true
        let synthesizedFrequencyResponse: [Double] = self.speechAnalyzer.synthesizedFrequencyResponse
        self.lineChartFull.clearChartData()
        self.lineChartFull.setChartData(synthesizedFrequencyResponse)
    }
    
    @IBAction func graphingModeChanged(sender: UISegmentedControl) {
        self.displayIdentifier = GraphingMode(rawValue: sender.selectedSegmentIndex)!
        self.showPlotForDisplayIdentifier(self.displayIdentifier, withAnalyzer: self.speechAnalyzer)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext) -> Void in
            self.showPlotForDisplayIdentifier(self.displayIdentifier, withAnalyzer: self.speechAnalyzer)
            }, completion: {(context: UIViewControllerTransitionCoordinatorContext) -> Void in
        })
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }
    
    func displayFormantFrequencies() {
        var formants: [Double] = self.speechAnalyzer.formants
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
        let fileURL = NSBundle.mainBundle().URLForResource(self.soundFileBaseNames[self.soundFileIdentifier], withExtension: "raw")!
        NSLog("Processing saved file %@", self.soundFileBaseNames[self.soundFileIdentifier])
        speechData = NSData(contentsOfURL: fileURL)!
        self.speechAnalyzer = SpeechAnalyzer(int16Samples: speechData, withFrequency: 44100)
        self.showPlotForDisplayIdentifier(self.displayIdentifier, withAnalyzer: self.speechAnalyzer)
    }
    
    /// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.indicatorImageView.image = UIImage(named: "green_light.png")
        self.inputSelector.setTitle("Microphone", forState: .Normal)
        self.speechIsFromMicrophone = true
        self.indicatorImageView.hidden = false
        self.statusLabel.text = "Listening ..."
        self.soundActivatedRecorder.startListening()
    }
    
    @IBAction func showHelp() {
        let url: NSURL = NSURL(string: "https://fulldecent.github.io/formant-analyzer/")!
        let webViewController: TOWebViewController = TOWebViewController(URL: url)
        webViewController.showActionButton = false
        self.presentViewController(UINavigationController(rootViewController: webViewController), animated: true, completion: { _ in })
    }
    
    @IBAction func showInputSelectSheet(sender: UIButton) {
        let alert: UIAlertController = UIAlertController(title: "Audio source", message: "Select the audio soucre to analyze", preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Microphone", style: .Default, handler: {
            (action: UIAlertAction) -> Void in
            self.inputSelector.setTitle("Microphone", forState: .Normal)
            self.speechIsFromMicrophone = true
            self.indicatorImageView.hidden = false
            self.statusLabel.text = "Waiting ..."
            self.soundActivatedRecorder.startListening()
        }))
        for basename: String in self.soundFileBaseNames {
            alert.addAction(UIAlertAction(title: basename, style: .Default, handler: {
                (action: UIAlertAction) -> Void in
                self.soundActivatedRecorder.stopListeningAndKeepRecordingIfInProgress(false)
                self.inputSelector.setTitle("File", forState: .Normal)
                self.speechIsFromMicrophone = false
                self.indicatorImageView.hidden = true
                self.soundFileIdentifier = self.soundFileBaseNames.indexOf(basename)!
                self.statusLabel.text = self.soundFileBaseNames[self.soundFileIdentifier]
                self.processRawBuffer()
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /// Get raw PCM data from the track
    func readSoundFileSamples(filePath: String) -> NSData {
        let retval = NSMutableData()
        let assetURL: NSURL = NSURL(fileURLWithPath: filePath)
        let asset = AVURLAsset(URL: assetURL)
        let track = asset.tracks[0]
        let reader = try! AVAssetReader(asset: asset)
        let settings: [String: NSNumber] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: 0,
            AVLinearPCMIsFloatKey: 0,
            AVLinearPCMIsBigEndianKey: 0
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        reader.addOutput(output)
        reader.startReading()
        // read the samples from the asset and append them subsequently
        while reader.status != .Completed {
            guard let buffer = output.copyNextSampleBuffer() else {
                continue
            }
            let blockBuffer = CMSampleBufferGetDataBuffer(buffer)!
            let size = CMBlockBufferGetDataLength(blockBuffer)
            let outBytes = NSMutableData(length: size)!
            CMBlockBufferCopyDataBytes(blockBuffer, 0, size, outBytes.mutableBytes)
            CMSampleBufferInvalidate(buffer)
            retval.appendData(outBytes)
        }
        return retval
    }
}

extension FirstViewController: FDSoundActivatedRecorderDelegate {
    func soundActivatedRecorderDidStartRecording(recorder: FDSoundActivatedRecorder!) {
        NSLog("STARTED RECORDING")
        self.indicatorImageView.image = UIImage(named: "blue_light.png")
        self.statusLabel.text = "Capturing sound"
    }
    
    func soundActivatedRecorderDidStopRecording(recorder: FDSoundActivatedRecorder!, andSavedSound didSave: Bool) {
        NSLog("STOPPED RECORDING")
        self.indicatorImageView.image = UIImage(named: "red_light.png")
        if didSave {
            self.statusLabel.text = "Processing sound"
            self.speechData = self.readSoundFileSamples(self.soundActivatedRecorder.recordedFilePath)
            self.speechAnalyzer = SpeechAnalyzer(int16Samples: self.speechData, withFrequency: 44100)
            self.showPlotForDisplayIdentifier(self.displayIdentifier, withAnalyzer: self.speechAnalyzer)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) / 2), dispatch_get_main_queue(), {() -> Void in
                self.indicatorImageView.image = UIImage(named: "green_light.png")
                self.statusLabel.text = "Listening ..."
                self.soundActivatedRecorder.startListening()
            })
        }
        else {
            self.statusLabel.text = "Retrying ..."
            if self.speechIsFromMicrophone {
                self.soundActivatedRecorder.startListening()
            }
        }
    }
}