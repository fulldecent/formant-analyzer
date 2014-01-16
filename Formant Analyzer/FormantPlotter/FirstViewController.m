//
//  FirstViewController.m
//  FormantPlotter
//
//  Created by William Entriken on 1/15/14.
//  Copyright (c) 2014 William Entriken. All rights reserved.
//

#import "FirstViewController.h"
#import "AudioDeviceManager.h"

typedef enum {GraphingModeSig, GraphingModeTrim, GraphingModeLPC, GraphingModeHW, GraphingModeFrmnt} GraphingModes;

@interface FirstViewController() <UIActionSheetDelegate>
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
// These buttons just set value of displayIdentifier appropriately, passes this value to plotView
// can calls the default display updating function, drawRect(), in plotView.

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
            displayIdentifier = sender.selectedSegmentIndex+1;
            [plotView setDisplayIdentifier:displayIdentifier];
            [plotView setNeedsDisplay];
            break;
        case GraphingModeFrmnt:
            displayIdentifier = sender.selectedSegmentIndex+1;
            [plotView setDisplayIdentifier:displayIdentifier];
            [plotView setNeedsDisplay];
            [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
            break;
    }
}



// This function is called half a second after the formant plot is displayed. It creates four text
// labels and puts that below the standard vowel diagram.
-(void) displayFormantFrequencies
{
    NSString *firstFLabel = [NSString stringWithFormat:@"Formant 1:%5.0f",[plotView firstFFreq]];
    firstFormantLabel.text = firstFLabel;
    NSString *secondFLabel = [NSString stringWithFormat:@"Formant 2:%5.0f",[plotView secondFFreq]];
    secondFormantLabel.text = secondFLabel;
    NSString *thirdFLabel = [NSString stringWithFormat:@"Formant 3:%5.0f",[plotView thirdFFreq]];
    thirdFormantLabel.text = thirdFLabel;
    NSString *fourthFLabel = [NSString stringWithFormat:@"Formant 4:%5.0f",[plotView fourthFFreq]];
    fourthFormantLabel.text = fourthFLabel;
}

// This function takes value from the slider, multiplies it with 10^7 and passes on this value to audioDeviceManager.
// This threshold is used to determine if microphone is listening to background chatter or real speaker. Keep the slider
// to a lower value in quiter environmant and higher for noisy environments.
-(IBAction) processThresholdSlider
{
    audioDeviceManager->energyThreshold = (unsigned long)(thresholdSlider.value * 10000000);
}

/* The following block reads two flags in audioDeviceManager to handle different stages of real-time data capturing. The audioDeviceManger starts with both of these flags in FALSE state, implying that it is waiting for a strong input signal. We display a message of 'Waiting ...' in this state.
 
 When strong input signal is detected, startCapturing becomes TRUE and remains true while signal remains strong. We display a message of 'Capturing ...' during this state.
 
 When the signal becomes weak again, both flags are true. We display a message of 'Processing ...'. When we are done with processing, we reset the two flags and display a message of 'Waiting ...' We also process recently captured frame.
 */

-(void) handleTimerTick
{
    if (liveSpeechSegments == TRUE) {           // Only do the following if we are processing live speech.
        
        // If strong signal appears (detected via flags of audioDeviceManager), display blue light.
        // Also reset dummyTimerTickCounter
        
        if (audioDeviceManager-> startCapturing == TRUE && audioDeviceManager->capturingComplete == FALSE)
        {
            [indicatorImageView setImage:[UIImage imageNamed:@"blue_light.png"]];
            [statusLabel setText:@"Capturing sound"];
            dummyTimerTickCounter = 0;
        }
        
        // If signal is no longer strong (detected via flags of audioDeviceManger), increment dummyTickCounter and
        // display a red light to indicate we are processing the captured signal.
        
        if (audioDeviceManager-> startCapturing == TRUE && audioDeviceManager->capturingComplete == TRUE)
        {
            if (dummyTimerTickCounter == 0)    // If we are just completed sound capturing
            {
                dummyTimerTickCounter++;
                
                [plotView setDisplayIdentifier:displayIdentifier];
                
                // Take the captured data from audioDeviceManger and pass it on to plotView
                // Also save the sound buffer locally on the device. This was done to capture data
                // with iPhone, export it to MATLAB and process offline. Not needed in final version.
                [plotView  getData:audioDeviceManager->longBuffer withLength:1024 * audioDeviceManager->bufferSegCount];
                [plotView setNeedsDisplay];
                
                [self performSelector:@selector(saveBuffer) withObject:nil afterDelay:0.1];
                [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
                
                [indicatorImageView setImage:[UIImage imageNamed:@"red_light.png"]];
                [statusLabel setText:@"Processing sound"];
            }
            else   // If sound capturing was done a few timer ticks ago, give a dummy delay of 10counts.
            {
                dummyTimerTickCounter++;
                if (dummyTimerTickCounter > 15)    // dummy delay is over. Reset everything for next capture.
                {
                    [indicatorImageView setImage:[UIImage imageNamed:@"green_light.png"]];
                    audioDeviceManager->bufferSegCount = 0;
                    audioDeviceManager->startCapturing = FALSE;
                    audioDeviceManager->capturingComplete = FALSE;
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
    NSData *rawData = [[NSData alloc] initWithBytes:audioDeviceManager->longBuffer length:1024 * audioDeviceManager->bufferSegCount * sizeof(short)];
    
    NSLog(@"Raw Data has length %d",[rawData length]);
    
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"lastSpeech"];
    
    [rawData writeToFile:filePath atomically:YES];
}

// Depending upon which stored speech segment is to be processed, the following function loads the appropriate
// binary data file from the main bundle of the app. The loaded data is put into rawBuffer and appropriate view
// is shown in plotView.

// If we are looking at 5th plot type (formant frequencies), four text labels are updated with a delay of 0.5 sec
-(void) processRawBuffer
{
    NSData *speechSegmentData;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[soundFileBaseNames objectAtIndex:soundFileIdentifier] ofType:@"raw"];
    speechSegmentData = [[NSData alloc] initWithContentsOfFile:filePath];
    
    [speechSegmentData getBytes:soundDataBuffer];
    
    
    //NSLog(@"Length of speech segment NSData is %d",[speechSegmentData length]);
    NSLog(@"Current base file name is %@",[soundFileBaseNames objectAtIndex:soundFileIdentifier]);
    
    [plotView setDisplayIdentifier:displayIdentifier];
    
    [plotView  getData:soundDataBuffer withLength:[speechSegmentData length]/sizeof(short)];
    [plotView setNeedsDisplay];
    
    if (displayIdentifier == 5) {
        [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
    }
}

// Processes last captured (and stored) speech segment. It loads binary data from a file titled
// lastSpeech, puts data into lastSegmentData and calls the plotView, which processed the audio buffer.
-(IBAction)processLastSegment
{
    NSData *lastSegmentData;
    
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"lastSpeech"];
    
    lastSegmentData = [[NSData alloc] initWithContentsOfFile:filePath];
    
    [lastSegmentData getBytes:soundDataBuffer];
    
    NSLog(@"Length of last segment NSData is %d",[lastSegmentData length]);
    
    [statusLabel setText:@"Last"];
    
    [plotView setDisplayIdentifier:displayIdentifier];
    
    [plotView  getData:soundDataBuffer withLength:[lastSegmentData length]/sizeof(short)];
    [plotView setNeedsDisplay];
    
    if (displayIdentifier == 5) {
        [self performSelector:@selector(displayFormantFrequencies) withObject:nil afterDelay:0.5];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize 7 names for 7 stored audio files.
    soundFileBaseNames = [[NSArray alloc] initWithObjects:@"arm",@"beat",@"bid",@"calm",@"cat",@"four",@"who", nil];
    
    dummyTimerTickCounter = 0;
    liveSpeechSegments = TRUE;
    
    displayIdentifier = 5;         // Starting display type is formant plot (last button).
    soundFileIdentifier = 0;        // Starting stored file to be processes is 'arm'.
    
    // Maximum length of captured speech segment is 1024000/44100 = 23.22 seconds.
    // There are no checks to see if someone intentionally keeps on speaking loudly
    // for a longer time. Such behaviour may cause a crash. Checks can be easily placed
    // in audioDeviceManager.
    
    soundDataBuffer = (short int *)(malloc(1024000 * sizeof(short int)));
    
    // Initial hidder/visible patter of the app.
    indicatorImageView.hidden = FALSE;
    sliderLabel.hidden = FALSE;
    thresholdSlider.hidden = FALSE;
    
    // Start setting up of audio capturing phenomenon
    audioDeviceManager = [[AudioDeviceManager alloc] init];
    [audioDeviceManager setUpData];
    audioDeviceManager->bufferSegCount = 0;
    audioDeviceManager->startCapturing = FALSE;
    audioDeviceManager->capturingComplete = FALSE;
    
    // Set a starting value of silence threshold = 30x10000000
    audioDeviceManager->energyThreshold = 300000000;
    
    
    // Clear all entries from the long audio buffer in audioDeviceManager.
    for (int j=0; j<1024000; j++) {
        audioDeviceManager->longBuffer[j] = 0;
    }
    
    // Plot formant frequencies of silence (2000 sample of initialized long buffer).
    
    [plotView getData:audioDeviceManager->longBuffer withLength:2000];
    [plotView setNeedsDisplay];
    
    // Setup audioDevice Manager. If it workds, put green light up and invite the user to speak.
    OSStatus status = [audioDeviceManager setUpAudioDevice];
    
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
    for (NSString *basename in soundFileBaseNames)
        [inputChoice addButtonWithTitle:basename];
    [inputChoice addButtonWithTitle:@"Cancel"];
    inputChoice.cancelButtonIndex = inputChoice.numberOfButtons-1;
    
    [inputChoice showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // Live speech processing
        [self.inputSelector setTitle:@"Microphone" forState:UIControlStateNormal];
        [self.statusLabel setText:@"Waiting ..."];
        liveSpeechSegments = TRUE;
        audioDeviceManager->startCapturing = FALSE;
        audioDeviceManager->capturingComplete = FALSE;
        indicatorImageView.hidden = FALSE;
        sliderLabel.hidden = FALSE;
        thresholdSlider.hidden = FALSE;
        [statusLabel setText:@"Waiting ..."];
        [self processLastSegment];
    } else if (buttonIndex < actionSheet.cancelButtonIndex) { // Saved file processing
        [self.inputSelector setTitle:@"File" forState:UIControlStateNormal];
        liveSpeechSegments = FALSE;
        audioDeviceManager->startCapturing = TRUE;
        audioDeviceManager->capturingComplete = TRUE;
        indicatorImageView.hidden = TRUE;
        sliderLabel.hidden = TRUE;
        thresholdSlider.hidden = TRUE;
        soundFileIdentifier = buttonIndex - 1;
        [statusLabel setText:[soundFileBaseNames objectAtIndex:soundFileIdentifier]];
        [self processRawBuffer];
        
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    free(soundDataBuffer);
}


@end
