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

typedef NS_ENUM(NSInteger, GraphingModes) {GraphingModeSig, GraphingModeLPC, GraphingModeHW, GraphingModeFrmnt} ;

@interface FirstViewController() <UIActionSheetDelegate, FDSoundActivatedRecorderDelegate>
@property int processingDelayTimeCounter;
@property GraphingModes displayIdentifier;            // What type of information is to be displayed in self.plotView.
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

// TODO: remove speech data parameter
- (void)showPlotForDisplayIdentifier:(GraphingModes)displayIdentifier withAnalyzer:(SpeechAnalyzer *)analyzer andSpeechData:(NSData *)data
{
    [self displayFormantFrequencies];

    //UGLIEST HACK
    FSLineChart *newChart = [[FSLineChart alloc] initWithFrame:self.lineChartFull.frame];
    [self.lineChartFull removeFromSuperview];
    [self.view addSubview:newChart];
    self.lineChartFull = newChart;

    //TODO: these should each be separate view classes
    if (displayIdentifier == GraphingModeSig) {
        [self drawSignalPlot];
    } else if (displayIdentifier == GraphingModeLPC) {
        [self drawLPCPlot];
    } else if (displayIdentifier == GraphingModeHW) {
        [self drawHwPlot];
    } else {
        // TEMP HACK
        self.plotView.formants = [self.speechAnalyzer findCleanFormants];
        self.plotView.hidden = NO;
        self.lineChartTopHalf.hidden = YES;
        self.lineChartBottomHalf.hidden = YES;
        self.lineChartFull.hidden = YES;
        [self.plotView setNeedsDisplay];
    }
}

- (void)drawSignalPlot
{
    self.plotView.hidden = YES;
    self.lineChartFull.hidden = YES;
    
    self.lineChartTopHalf.hidden = NO;
    self.lineChartTopHalf.drawInnerGrid = NO;
    self.lineChartTopHalf.axisLineWidth = 0;
    self.lineChartTopHalf.margin = 0;
    self.lineChartTopHalf.axisWidth = self.lineChartTopHalf.frame.size.width;
    self.lineChartTopHalf.axisHeight = self.lineChartTopHalf.frame.size.height;
    self.lineChartTopHalf.backgroundColor = [UIColor clearColor];
    self.lineChartTopHalf.fillColor = [UIColor blueColor];
    self.lineChartBottomHalf.hidden = NO;
    self.lineChartBottomHalf.drawInnerGrid = NO;
    self.lineChartBottomHalf.axisLineWidth = 0;
    self.lineChartBottomHalf.margin = 0;
    self.lineChartBottomHalf.axisWidth = self.lineChartTopHalf.frame.size.width;
    self.lineChartBottomHalf.axisHeight = self.lineChartTopHalf.frame.size.height;
    self.lineChartBottomHalf.backgroundColor = [UIColor clearColor];
    self.lineChartBottomHalf.fillColor = [UIColor blueColor];
    
    NSArray *plottableValuesHigh = [self.speechAnalyzer downsampleToSamples:400];
    NSMutableArray *plottableValuesLow = [NSMutableArray array];
    for (NSNumber *number in plottableValuesHigh) {
        [plottableValuesLow addObject:@(-number.doubleValue)];
    }
    [self.lineChartTopHalf clearChartData];
    [self.lineChartTopHalf setChartData:plottableValuesHigh];
    [self.lineChartBottomHalf clearChartData];
    [self.lineChartBottomHalf setChartData:plottableValuesLow];
    
    /* 
     TODO: Here do trimming for vowel isolation, show tinted overlay
    NSRange power = [self.speechAnalyzer strongSignalRange];
    NSRange vowel = [self.speechAnalyzer truncateRangeTails:power];
    double samples = self.speechAnalyzer.totalSamples.doubleValue;
    CGRect powerFrame = CGRectMake(self.lineChartTopHalf.frame.origin.x + power.location/samples*self.lineChartTopHalf.frame.size.width,
                                   self.lineChartTopHalf.frame.origin.y,
                                   power.length/samples*self.lineChartTopHalf.frame.size.width,
                                   self.lineChartTopHalf.frame.size.height);
    
    self.trimPower = [[UIView alloc] initWithFrame:powerFrame];
    self.trimPower.backgroundColor = [UIColor colorWithHue:0.75 saturation:1 brightness:1 alpha:0.2];
    [self.view addSubview:self.trimPower];
    */
}

- (void)drawLPCPlot
{
    self.plotView.hidden = YES;
    self.lineChartTopHalf.hidden = YES;
    self.lineChartBottomHalf.hidden = YES;
    self.lineChartFull.hidden = NO;
    
    // Index label properties
    self.lineChartFull.labelForIndex = ^(NSUInteger item) {
        return [NSString stringWithFormat:@"%ld", (long)item];
    };
    
    // Value label properties
    self.lineChartFull.labelForValue = ^(CGFloat value) {
        return [NSString stringWithFormat:@"%.02f", value];
    };
    self.lineChartFull.valueLabelPosition = ValueLabelLeft;
    
    // Number of visible step in the chart
    self.lineChartFull.verticalGridStep = 3;
    self.lineChartFull.horizontalGridStep = 20;
    
    // Margin of the chart
    self.lineChartFull.margin = 40;
    
    self.lineChartFull.axisWidth = self.lineChartFull.frame.size.width - 2 * self.lineChartFull.margin;
    self.lineChartFull.axisHeight = self.lineChartFull.frame.size.height - 2 * self.lineChartFull.margin;
    
    // Decoration parameters, let you pick the color of the line as well as the color of the axis
    self.lineChartFull.axisLineWidth = 1;
    
    // Chart parameters
    self.lineChartFull.color = [UIColor blackColor];
    self.lineChartFull.fillColor = [UIColor blueColor];
    self.lineChartFull.backgroundColor = [UIColor clearColor];
    
    // Grid parameters
    self.lineChartFull.drawInnerGrid = YES;
    
    
    NSArray *lpcCoefficients = [self.speechAnalyzer lpcCoefficients];
    [self.lineChartFull clearChartData];
    [self.lineChartFull setChartData:lpcCoefficients];
}

- (void)drawHwPlot
{
    self.plotView.hidden = YES;
    self.lineChartTopHalf.hidden = YES;
    self.lineChartBottomHalf.hidden = YES;
    self.lineChartFull.hidden = NO;
    
    // Index label properties
    self.lineChartFull.labelForIndex = ^(NSUInteger item) {
        return [NSString stringWithFormat:@"%.0f kHz", (double)item/60];
    };
    
    // Value label properties
    self.lineChartFull.labelForValue = ^(CGFloat value) {
        return [NSString stringWithFormat:@"%.02f", value];
    };
    self.lineChartFull.valueLabelPosition = ValueLabelLeft;
    
    // Number of visible step in the chart
    self.lineChartFull.verticalGridStep = 3;
    self.lineChartFull.horizontalGridStep = 5;
    
    // Margin of the chart
    self.lineChartFull.margin = 40;
    
    self.lineChartFull.axisWidth = self.lineChartFull.frame.size.width - 2 * self.lineChartFull.margin;
    self.lineChartFull.axisHeight = self.lineChartFull.frame.size.height - 2 * self.lineChartFull.margin;
    
    // Decoration parameters, let you pick the color of the line as well as the color of the axis
    self.lineChartFull.axisLineWidth = 1;
    
    // Chart parameters
    self.lineChartFull.color = [UIColor blackColor];
    self.lineChartFull.fillColor = [UIColor blueColor];
    self.lineChartFull.backgroundColor = [UIColor clearColor];
    
    // Grid parameters
    self.lineChartFull.drawInnerGrid = YES;
    
    NSArray *synthesizedFrequencyResponse = [self.speechAnalyzer synthesizedFrequencyResponse];
    [self.lineChartFull clearChartData];
    [self.lineChartFull setChartData:synthesizedFrequencyResponse];
}

////////////////////////////////////////
#define ORDER 20
#define EPS 2.0e-6
#define EPSS 1.0e-7
#define MR 8
#define MT 10
#define MAXIT (MT*MR)



/** Update display for new view mode
 @param sender The UISegmentedControl which has chosen the new display mode
 */
- (IBAction)graphingModeChanged:(UISegmentedControl *)sender
{
    self.displayIdentifier = sender.selectedSegmentIndex;
    [self showPlotForDisplayIdentifier:self.displayIdentifier withAnalyzer:self.speechAnalyzer andSpeechData:self.speechData];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self showPlotForDisplayIdentifier:self.displayIdentifier withAnalyzer:self.speechAnalyzer andSpeechData:self.speechData];
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         
     }];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

// This function is called half a second after the formant plot is displayed. It creates four text
// labels and puts that below the standard vowel diagram.
- (void)displayFormantFrequencies
{
    NSArray *formants = [self.speechAnalyzer findCleanFormants];
    
    NSString *firstFLabel = [NSString stringWithFormat:@"Formant 1:%5.0f",((NSNumber *)formants[0]).floatValue];
    self.firstFormantLabel.text = firstFLabel;
    NSString *secondFLabel = [NSString stringWithFormat:@"Formant 2:%5.0f",((NSNumber *)formants[1]).floatValue];
    self.secondFormantLabel.text = secondFLabel;
    NSString *thirdFLabel = [NSString stringWithFormat:@"Formant 3:%5.0f",((NSNumber *)formants[2]).floatValue];
    self.thirdFormantLabel.text = thirdFLabel;
    NSString *fourthFLabel = [NSString stringWithFormat:@"Formant 4:%5.0f",((NSNumber *)formants[3]).floatValue];
    self.fourthFormantLabel.text = fourthFLabel;
}

// Depending upon which stored speech segment is to be processed, the following function loads the appropriate
// binary data file from the main bundle of the app. The loaded data is put into rawBuffer and appropriate view
// is shown in self.plotView.

// If we are looking at 5th plot type (formant frequencies), four text labels are updated with a delay of 0.5 sec
- (void)processRawBuffer
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:self.soundFileBaseNames[self.soundFileIdentifier] ofType:@"raw"];
    NSLog(@"Processing saved file %@",self.soundFileBaseNames[self.soundFileIdentifier]);
    self.speechData = [[NSData alloc] initWithContentsOfFile:filePath];
    self.speechAnalyzer = [SpeechAnalyzer analyzerWithData:self.speechData];
    [self showPlotForDisplayIdentifier:self.displayIdentifier withAnalyzer:self.speechAnalyzer andSpeechData:self.speechData];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize 7 names for 7 stored audio files.
    self.soundFileBaseNames = @[@"arm",@"beat",@"bid",@"calm",@"cat",@"four",@"who"];
    
    self.processingDelayTimeCounter = 0;
    self.speechIsFromMicrophone = YES;
    
    self.displayIdentifier = 0;         // Starting display type is formant plot (last button).
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
        self.speechAnalyzer = [SpeechAnalyzer analyzerWithData:self.speechData];
        [self showPlotForDisplayIdentifier:self.displayIdentifier withAnalyzer:self.speechAnalyzer andSpeechData:self.speechData];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.indicatorImageView setImage:[UIImage imageNamed:@"green_light.png"]];
            [self.statusLabel setText:@"Waiting ..."];
            [self.soundActivatedRecorder startListening];
        });
    } else {
        [self.statusLabel setText:@"Retrying ..."];
    }
}

@end
