//
//  FirstViewController.m
//  FormantPlotter
//
//  Created by William Entriken on 1/15/14.
//  Copyright (c) 2014 William Entriken. All rights reserved.
//

#import "FirstViewController.h"
#import <TOWebViewController.h>
#import <FDSoundActivatedRecorder.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "SpeechAnalyzer.h"

typedef NS_ENUM(NSInteger, GraphingModes) {GraphingModeSig, GraphingModeTrim, GraphingModeLPC, GraphingModeHW, GraphingModeFrmnt} ;

@interface FirstViewController() <UIActionSheetDelegate, FDSoundActivatedRecorderDelegate>
@property int processingDelayTimeCounter;
@property long displayIdentifier;                     // What type of information (1 out of 5) is to be displayed in self.plotView.
@property NSTimer *masterTimer;                       // Timer to manage three phases of soud capturing process
@property FDSoundActivatedRecorder *soundActivatedRecorder;

@property BOOL speechIsFromMicrophone;                // Whether we are processing live speech or stored samples.
@property NSInteger soundFileIdentifier;              // Which stored file (1 out of 7) is being processed
@property NSArray *soundFileBaseNames;                // Array of names of 7 stored sound files.

@property SpeechAnalyzer *speechAnalyzer;
@property NSData *speechData;

- (void)processRawBuffer;
- (void)displayFormantFrequencies;

@end

@implementation FirstViewController

- (void)drawSignalPlot
{
    self.speechAnalyzer = [SpeechAnalyzer analyzerWithData:self.speechData];
    self.plotView.hidden = YES;
    self.lineChart.hidden = NO;
    
    // data transform
    short int *dataBuffer = (short int*)self.speechData.bytes;
    
    NSRange strongRange = [self.speechAnalyzer strongSignalRange];
    long strongStartIdx = strongRange.location;
    long strongEndIdx = strongRange.location + strongRange.length;
    long chunkSamples = (strongEndIdx - strongStartIdx) / 400;
    NSMutableArray *plottableValuesHigh = [NSMutableArray array];
    NSMutableArray *plottableValuesLow = [NSMutableArray array];
    
    for (long chunkIdx=0; chunkIdx<400; chunkIdx++) {
        long chunkMinValue = INFINITY;
        long chunkMaxValue = -INFINITY;
        for (long j=0; j<chunkSamples; j++) {
            long dataBufferIdx = j + strongStartIdx + chunkIdx*chunkSamples;
            chunkMinValue = MIN(chunkMinValue, dataBuffer[dataBufferIdx]);
            chunkMaxValue = MAX(chunkMaxValue, dataBuffer[dataBufferIdx]);
        }
        [plottableValuesHigh addObject:@(chunkMaxValue)];
        [plottableValuesLow addObject:@(chunkMinValue)];
    }
    
    for (NSNumber *number in plottableValuesHigh) {
        NSLog(@"%@", number);
    }
    for (NSNumber *number in plottableValuesLow) {
        NSLog(@"%@", number);
    }
    [self.lineChart setChartData:plottableValuesHigh];
    
}


/** Update display for new view mode
 @param sender The UISegmentedControl which has chosen the new display mode
 */
- (IBAction)graphingModeChanged:(UISegmentedControl *)sender
{
    self.displayIdentifier = sender.selectedSegmentIndex+1;
    [self.plotView setDisplayIdentifier:self.displayIdentifier];
    [self.plotView setNeedsDisplay];
    
    if ((GraphingModes)sender.selectedSegmentIndex == GraphingModeFrmnt)
        [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
    
    if ((GraphingModes)sender.selectedSegmentIndex == GraphingModeSig) {
        [self drawSignalPlot];
    } else {
        // TEMP HACK
        self.plotView.hidden = NO;
        self.lineChart.hidden = YES;
        
    }
}

// This function is called half a second after the formant plot is displayed. It creates four text
// labels and puts that below the standard vowel diagram.
- (void)displayFormantFrequencies
{
    NSString *firstFLabel = [NSString stringWithFormat:@"Formant 1:%5.0f",[self.plotView firstFFreq]];
    self.firstFormantLabel.text = firstFLabel;
    NSString *secondFLabel = [NSString stringWithFormat:@"Formant 2:%5.0f",[self.plotView secondFFreq]];
    self.secondFormantLabel.text = secondFLabel;
    NSString *thirdFLabel = [NSString stringWithFormat:@"Formant 3:%5.0f",[self.plotView thirdFFreq]];
    self.thirdFormantLabel.text = thirdFLabel;
    NSString *fourthFLabel = [NSString stringWithFormat:@"Formant 4:%5.0f",[self.plotView fourthFFreq]];
    self.fourthFormantLabel.text = fourthFLabel;
}

// Depending upon which stored speech segment is to be processed, the following function loads the appropriate
// binary data file from the main bundle of the app. The loaded data is put into rawBuffer and appropriate view
// is shown in self.plotView.

// If we are looking at 5th plot type (formant frequencies), four text labels are updated with a delay of 0.5 sec
- (void)processRawBuffer
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:self.soundFileBaseNames[self.soundFileIdentifier] ofType:@"raw"];
    self.speechData = [[NSData alloc] initWithContentsOfFile:filePath];
    
    //NSLog(@"Length of speech segment NSData is %d",[speechSegmentData length]);
    NSLog(@"Current base file name is %@",self.soundFileBaseNames[self.soundFileIdentifier]);
    
    [self.plotView setDisplayIdentifier:self.displayIdentifier];
    
    [self.plotView getData:(short *)self.speechData.bytes withLength:self.speechData.length/sizeof(short)];
    [self.plotView setNeedsDisplay];
    
    if (self.displayIdentifier == 5) {
        [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
    }
    
    if ((GraphingModes)self.displayIdentifier == GraphingModeSig) {
        [self drawSignalPlot];
    } else {
        // TEMP HACK
        self.plotView.hidden = NO;
        self.lineChart.hidden = YES;
        
    }
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize 7 names for 7 stored audio files.
    self.soundFileBaseNames = @[@"arm",@"beat",@"bid",@"calm",@"cat",@"four",@"who"];
    
    self.processingDelayTimeCounter = 0;
    self.speechIsFromMicrophone = YES;
    
    self.displayIdentifier = 5;         // Starting display type is formant plot (last button).
    self.soundFileIdentifier = 0;        // Starting stored file to be processes is 'arm'.
    
    // Initial hidder/visible patter of the app.
    self.indicatorImageView.hidden = NO;
    
    [self.plotView setNeedsDisplay];
    
    // Start master timer with tick time of 0.1 seconds.
    self.masterTimer = nil;
    self.soundActivatedRecorder = [[FDSoundActivatedRecorder alloc] init];
    self.soundActivatedRecorder.delegate = self;
    [self.soundActivatedRecorder startListening];
}

- (IBAction)showHelp {
    NSURL *url = [NSURL URLWithString:@"https://fulldecent.github.io/formant-analyzer/"];
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:url];
    webViewController.showActionButton = false;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:webViewController] animated:YES completion:nil];
}

- (IBAction)showInputSelectSheet:(id)sender
{
    UIActionSheet *inputChoice = [[UIActionSheet alloc] initWithTitle:@"Audio source" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [inputChoice addButtonWithTitle:@"Microphone"];
    for (NSString *basename in self.soundFileBaseNames)
        [inputChoice addButtonWithTitle:basename];
    [inputChoice addButtonWithTitle:@"Cancel"];
    inputChoice.cancelButtonIndex = inputChoice.numberOfButtons-1;
    [inputChoice showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // Live speech processing
        [self.inputSelector setTitle:@"Microphone" forState:UIControlStateNormal];
        self.speechIsFromMicrophone = YES;
        self.indicatorImageView.hidden = NO;
        [self.statusLabel setText:@"Waiting ..."];
        [self.soundActivatedRecorder startListening];
    } else if (buttonIndex < actionSheet.cancelButtonIndex) { // Saved file processing
        [self.soundActivatedRecorder stopListeningAndKeepRecordingIfInProgress:NO];
        [self.inputSelector setTitle:@"File" forState:UIControlStateNormal];
        self.speechIsFromMicrophone = NO;
        self.indicatorImageView.hidden = YES;
        self.soundFileIdentifier = buttonIndex - 1;
        [self.statusLabel setText:self.soundFileBaseNames[self.soundFileIdentifier]];
        [self processRawBuffer];
    }
}

- (NSData *)readSoundFileSamples:(NSString *)filePath
{
    // Get raw PCM data from the track
    NSURL *assetURL = [NSURL fileURLWithPath:filePath];
    NSMutableData *data = [[NSMutableData alloc] init];
    
    const uint32_t sampleRate = 16000; // 16k sample/sec
    const uint16_t bitDepth = 16; // 16 bit/sample/channel
    //const uint16_t channels = 1; // 2 channel/sample (stereo)
    
    NSDictionary *opts = [NSDictionary dictionary];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:assetURL options:opts];
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:NULL];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                              [NSNumber numberWithFloat:(float)sampleRate], AVSampleRateKey,
                              [NSNumber numberWithInt:bitDepth], AVLinearPCMBitDepthKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey, nil];
    
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc] initWithTrack:[[asset tracks] objectAtIndex:0] outputSettings:settings];
    [reader addOutput:output];
    [reader startReading];
    
    // read the samples from the asset and append them subsequently
    while ([reader status] != AVAssetReaderStatusCompleted) {
        CMSampleBufferRef buffer = [output copyNextSampleBuffer];
        if (buffer == NULL) continue;
        
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(buffer);
        size_t size = CMBlockBufferGetDataLength(blockBuffer);
        uint8_t *outBytes = malloc(size);
        CMBlockBufferCopyDataBytes(blockBuffer, 0, size, outBytes);
        CMSampleBufferInvalidate(buffer);
        CFRelease(buffer);
        [data appendBytes:outBytes length:size];
        free(outBytes);
    }
    
    return data;
    
}

#pragma mark - FDSoundActivatedRecorderDelegate

- (void)soundActivatedRecorderDidStartRecording:(FDSoundActivatedRecorder *)recorder
{
    NSLog(@"STARTED RECORDING");
    [self.indicatorImageView setImage:[UIImage imageNamed:@"blue_light.png"]];
    [self.statusLabel setText:@"Capturing sound"];
}

- (void)soundActivatedRecorderDidStopRecording:(FDSoundActivatedRecorder *)recorder andSavedSound:(BOOL)didSave
{
    NSLog(@"STOPPED RECORDING");
    [self.indicatorImageView setImage:[UIImage imageNamed:@"red_light.png"]];
    
    if (didSave) {
        [self.statusLabel setText:@"Processing sound"];
        self.speechData = [self readSoundFileSamples:self.soundActivatedRecorder.recordedFilePath];
        
        [self.plotView setDisplayIdentifier:self.displayIdentifier];
        [self.plotView getData:self.speechData];
        [self.plotView setNeedsDisplay];
        
        if (self.displayIdentifier == 5) {
            [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
        }
        
        if ((GraphingModes)self.displayIdentifier == GraphingModeSig) {
            [self drawSignalPlot];
        } else {
            // TEMP HACK
            self.plotView.hidden = NO;
            self.lineChart.hidden = YES;
            
        }
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.indicatorImageView setImage:[UIImage imageNamed:@"green_light.png"]];
            [self.statusLabel setText:@"Waiting ..."];
            [self.soundActivatedRecorder startListening];
        });
    } else {
        [self.statusLabel setText:@"Waiting ..."];
    }
}

@end
