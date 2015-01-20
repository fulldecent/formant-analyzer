//
//  FirstViewController.m
//  FormantPlotter
//
//  Created by William Entriken on 1/15/14.
//  Copyright (c) 2014 William Entriken. All rights reserved.
//

#import "FirstViewController.h"
#import "audioDeviceManager.h"
#import <TOWebViewController.h>

typedef NS_ENUM(NSInteger, GraphingModes) {GraphingModeSig, GraphingModeTrim, GraphingModeLPC, GraphingModeHW, GraphingModeFrmnt} ;

@interface FirstViewController() <UIActionSheetDelegate>
@property short int *soundDataBuffer;                    // A pointer to long sound buffer to be captured.
@property int dummyTimerTickCounter;
@property BOOL liveSpeechSegments;               // Whether we are processing live speech or stored samples.
@property int soundFileIdentifier;               // Which stored file (1 out of 7) is being processed
@property int displayIdentifier;                 // What type of information (1 out of 5) is to be displayed in self.plotView.
@property NSArray *soundFileBaseNames;           // Array of names of 7 stored sound files.
@property AudioDeviceManager *audioDeviceManager;
@property NSTimer *masterTimer;                          // Timer to manage three phases of soud capturing process

- (void)processRawBuffer;
- (void)displayFormantFrequencies;

@end

@implementation FirstViewController

@synthesize indicatorImageView;
@synthesize masterTimer;
@synthesize statusLabel;
@synthesize firstFormantLabel;
@synthesize secondFormantLabel;
@synthesize thirdFormantLabel;
@synthesize fourthFormantLabel;
@synthesize sliderLabel;
@synthesize graphingMode;

@synthesize thresholdSlider;

// One of the following 5 functions is called when one of the 5 buttons in analysis mode is touched.
// These buttons just set value of self.displayIdentifier appropriately, passes this value to self.plotView
// can calls the default display updating function, drawRect(), in self.plotView.

// The fifth function is different. After calling drawRect(), it calls another fuction
// displayFormantFrequencies after a delay of 0.5 seconds so that the values are
// calculated and available when we retrieve them with a delay of 0.5 second.

- (IBAction)graphingModeChanged:(UISegmentedControl *)sender
{
    switch ((GraphingModes)sender.selectedSegmentIndex) {
        case GraphingModeSig:
        case GraphingModeTrim:
        case GraphingModeLPC:
        case GraphingModeHW:
            self.displayIdentifier = sender.selectedSegmentIndex+1;
            [self.plotView setDisplayIdentifier:self.displayIdentifier];
            [self.plotView setNeedsDisplay];
            break;
        case GraphingModeFrmnt:
            self.displayIdentifier = sender.selectedSegmentIndex+1;
            [self.plotView setDisplayIdentifier:self.displayIdentifier];
            [self.plotView setNeedsDisplay];
            [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
            break;
    }
}



// This function is called half a second after the formant plot is displayed. It creates four text
// labels and puts that below the standard vowel diagram.
-(void) displayFormantFrequencies
{
    NSString *firstFLabel = [NSString stringWithFormat:@"Formant 1:%5.0f",[self.plotView firstFFreq]];
    firstFormantLabel.text = firstFLabel;
    NSString *secondFLabel = [NSString stringWithFormat:@"Formant 2:%5.0f",[self.plotView secondFFreq]];
    secondFormantLabel.text = secondFLabel;
    NSString *thirdFLabel = [NSString stringWithFormat:@"Formant 3:%5.0f",[self.plotView thirdFFreq]];
    thirdFormantLabel.text = thirdFLabel;
    NSString *fourthFLabel = [NSString stringWithFormat:@"Formant 4:%5.0f",[self.plotView fourthFFreq]];
    fourthFormantLabel.text = fourthFLabel;
}

// This function takes value from the slider, multiplies it with 10^7 and passes on this value to self.audioDeviceManager.
// This threshold is used to determine if microphone is listening to background chatter or real speaker. Keep the slider
// to a lower value in quiter environmant and higher for noisy environments.
-(IBAction) processThresholdSlider
{
    self.self.audioDeviceManager->energyThreshold = (unsigned long)(thresholdSlider.value * 10000000);
}

/* The following block reads two flags in self.audioDeviceManager to handle different stages of real-time data capturing. The audioDeviceManger starts with both of these flags in NO state, implying that it is waiting for a strong input signal. We display a message of 'Waiting ...' in this state.
 
 When strong input signal is detected, startCapturing becomes YES and remains true while signal remains strong. We display a message of 'Capturing ...' during this state.
 
 When the signal becomes weak again, both flags are true. We display a message of 'Processing ...'. When we are done with processing, we reset the two flags and display a message of 'Waiting ...' We also process recently captured frame.
 */

-(void) handleTimerTick
{
    if (self.liveSpeechSegments == YES) {           // Only do the following if we are processing live speech.
        
        // If strong signal appears (detected via flags of self.audioDeviceManager), display blue light.
        // Also reset dummyTimerTickCounter
        
        if (self.audioDeviceManager-> startCapturing == YES && self.audioDeviceManager->capturingComplete == NO)
        {
            [indicatorImageView setImage:[UIImage imageNamed:@"blue_light.png"]];
            [statusLabel setText:@"Capturing sound"];
            self.dummyTimerTickCounter = 0;
        }
        
        // If signal is no longer strong (detected via flags of audioDeviceManger), increment dummyTickCounter and
        // display a red light to indicate we are processing the captured signal.
        
        if (self.audioDeviceManager-> startCapturing == YES && self.audioDeviceManager->capturingComplete == YES)
        {
            if (self.dummyTimerTickCounter == 0)    // If we are just completed sound capturing
            {
                self.dummyTimerTickCounter++;
                
                [self.plotView setDisplayIdentifier:self.displayIdentifier];
                
                // Take the captured data from audioDeviceManger and pass it on to self.plotView
                // Also save the sound buffer locally on the device. This was done to capture data
                // with iPhone, export it to MATLAB and process offline. Not needed in final version.
                [self.plotView  getData:self.audioDeviceManager->longBuffer withLength:1024 * self.audioDeviceManager->bufferSegCount];
                [self.plotView setNeedsDisplay];
                
                [self performSelector:@selector(saveBuffer) withObject:nil afterDelay:0.1];
                [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
                
                [indicatorImageView setImage:[UIImage imageNamed:@"red_light.png"]];
                [statusLabel setText:@"Processing sound"];
            }
            else   // If sound capturing was done a few timer ticks ago, give a dummy delay of 10counts.
            {
                self.dummyTimerTickCounter++;
                if (self.dummyTimerTickCounter > 15)    // dummy delay is over. Reset everything for next capture.
                {
                    [indicatorImageView setImage:[UIImage imageNamed:@"green_light.png"]];
                    self.audioDeviceManager->bufferSegCount = 0;
                    self.audioDeviceManager->startCapturing = NO;
                    self.audioDeviceManager->capturingComplete = NO;
                    [statusLabel setText:@"Waiting ..."];
                }
            }
        }
    }
}

// Following function saves captured speech in Documents folder (on the device) with name lastSpeech.
// It is a raw dump of catured data.
-(void) saveBuffer
{
    NSData *rawData = [[NSData alloc] initWithBytes:self.audioDeviceManager->longBuffer length:1024 * self.audioDeviceManager->bufferSegCount * sizeof(short)];
    
    NSLog(@"Raw Data has length %d",[rawData length]);
    
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"lastSpeech"];
    
    [rawData writeToFile:filePath atomically:YES];
}

// Depending upon which stored speech segment is to be processed, the following function loads the appropriate
// binary data file from the main bundle of the app. The loaded data is put into rawBuffer and appropriate view
// is shown in self.plotView.

// If we are looking at 5th plot type (formant frequencies), four text labels are updated with a delay of 0.5 sec
-(void) processRawBuffer
{
    NSData *speechSegmentData;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:self.soundFileBaseNames[self.soundFileIdentifier] ofType:@"raw"];
    speechSegmentData = [[NSData alloc] initWithContentsOfFile:filePath];
    
    [speechSegmentData getBytes:self.soundDataBuffer];
    
    
    //NSLog(@"Length of speech segment NSData is %d",[speechSegmentData length]);
    NSLog(@"Current base file name is %@",self.soundFileBaseNames[self.soundFileIdentifier]);
    
    [self.plotView setDisplayIdentifier:self.displayIdentifier];
    
    [self.plotView  getData:self.soundDataBuffer withLength:[speechSegmentData length]/sizeof(short)];
    [self.plotView setNeedsDisplay];
    
    if (self.displayIdentifier == 5) {
        [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
    }
}

// Processes last captured (and stored) speech segment. It loads binary data from a file titled
// lastSpeech, puts data into lastSegmentData and calls the self.plotView, which processed the audio buffer.
-(IBAction)processLastSegment
{
    NSData *lastSegmentData;
    
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"lastSpeech"];
    
    lastSegmentData = [[NSData alloc] initWithContentsOfFile:filePath];
    
    [lastSegmentData getBytes:self.soundDataBuffer];
    
    NSLog(@"Length of last segment NSData is %d",[lastSegmentData length]);
    
    [statusLabel setText:@"Last"];
    
    [self.plotView setDisplayIdentifier:self.displayIdentifier];
    
    [self.plotView  getData:self.soundDataBuffer withLength:[lastSegmentData length]/sizeof(short)];
    [self.plotView setNeedsDisplay];
    
    if (self.displayIdentifier == 5) {
        [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize 7 names for 7 stored audio files.
    self.soundFileBaseNames = @[@"arm",@"beat",@"bid",@"calm",@"cat",@"four",@"who"];
    
    self.dummyTimerTickCounter = 0;
    self.liveSpeechSegments = YES;
    
    self.displayIdentifier = 5;         // Starting display type is formant plot (last button).
    self.soundFileIdentifier = 0;        // Starting stored file to be processes is 'arm'.
    
    // Maximum length of captured speech segment is 1024000/44100 = 23.22 seconds.
    // There are no checks to see if someone intentionally keeps on speaking loudly
    // for a longer time. Such behaviour may cause a crash. Checks can be easily placed
    // in self.audioDeviceManager.
    
    self.soundDataBuffer = (short int *)(malloc(1024000 * sizeof(short int)));
    
    // Initial hidder/visible patter of the app.
    indicatorImageView.hidden = NO;
    sliderLabel.hidden = NO;
    thresholdSlider.hidden = NO;
    
    // Start setting up of audio capturing phenomenon
    self.audioDeviceManager = [[AudioDeviceManager alloc] init];
    [self.audioDeviceManager setUpData];
    self.audioDeviceManager->bufferSegCount = 0;
    self.audioDeviceManager->startCapturing = NO;
    self.audioDeviceManager->capturingComplete = NO;
    
    // Set a starting value of silence threshold = 30x10000000
    self.audioDeviceManager->energyThreshold = 300000000;
    
    
    // Clear all entries from the long audio buffer in self.audioDeviceManager.
    for (int j=0; j<1024000; j++) {
        self.audioDeviceManager->longBuffer[j] = 0;
    }
    
    // Plot formant frequencies of silence (2000 sample of initialized long buffer).
    
    [self.plotView getData:self.audioDeviceManager->longBuffer withLength:2000];
    [self.plotView setNeedsDisplay];
    
    // Setup audioDevice Manager. If it workds, put green light up and invite the user to speak.
    OSStatus status = [self.audioDeviceManager setUpAudioDevice];
    
    if (status == noErr) {
        [indicatorImageView setImage:[UIImage imageNamed:@"green_light.png"]];
        [statusLabel setText:@"Waiting ..."];
    }
    else
    {
        indicatorImageView.image = nil;
        NSLog(@"Error starting audio services");
    }
    
    // Start with empty formant frequency values.
    [firstFormantLabel setText:@"Formant 1: "];
    [secondFormantLabel setText:@"Formant 2: "];
    [thirdFormantLabel setText:@"Formant 3: "];
    [fourthFormantLabel setText:@"Formant 4: "];
    
    // Start master timer with tick time of 0.1 seconds.
    masterTimer = nil;
    masterTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(handleTimerTick) userInfo:nil repeats:YES];
    
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

- (IBAction)showHelp {
    NSURL *url = [NSURL URLWithString:@"https://fulldecent.github.io/formant-analyzer/"];
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:url];
    webViewController.showActionButton = false;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:webViewController] animated:YES completion:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // Live speech processing
        [self.inputSelector setTitle:@"Microphone" forState:UIControlStateNormal];
        [self.statusLabel setText:@"Waiting ..."];
        self.liveSpeechSegments = YES;
        self.audioDeviceManager->startCapturing = NO;
        self.audioDeviceManager->capturingComplete = NO;
        indicatorImageView.hidden = NO;
        sliderLabel.hidden = NO;
        thresholdSlider.hidden = NO;
        [statusLabel setText:@"Waiting ..."];
        [self processLastSegment];
    } else if (buttonIndex < actionSheet.cancelButtonIndex) { // Saved file processing
        [self.inputSelector setTitle:@"File" forState:UIControlStateNormal];
        self.liveSpeechSegments = NO;
        self.audioDeviceManager->startCapturing = YES;
        self.audioDeviceManager->capturingComplete = YES;
        indicatorImageView.hidden = YES;
        sliderLabel.hidden = YES;
        thresholdSlider.hidden = YES;
        self.soundFileIdentifier = buttonIndex - 1;
        [statusLabel setText:self.soundFileBaseNames[self.soundFileIdentifier]];
        [self processRawBuffer];
        
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    free(self.soundDataBuffer);
}

@end
