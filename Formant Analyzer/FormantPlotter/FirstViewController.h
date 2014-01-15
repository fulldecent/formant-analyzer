//
//  FirstViewController.h
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

/*
 *******************************************************
 
 This is the main view controller that manages our capture/analysis workflow. 
 There are a lot of buttons, a slider, and a few text label on the view. Some
 of these elements are hidden depending upon the pahse (capture or analysis). 
 It would be better to eleminate analyze section or move it to a separate tab.

 *******************************************************
 */

#import <UIKit/UIKit.h>
#import "AudioDeviceManager.h"
#import "PlotView.h"



@interface FirstViewController : UIViewController {
    
    AudioDeviceManager *audioDeviceManager;
    
    IBOutlet UIImageView *indicatorImageView;      // Displayes an image based on strength of imput audio
    IBOutlet PlotView *plotView;                   // An instance of PlotView, for plotting of results.
    
    NSTimer *masterTimer;                          // Timer to manage three phases of soud capturing process
    
    short int *soundDataBuffer;                    // A pointer to long sound buffer to be captured.
        
    // Different GUI elements. They are declared IBOutlet as they need to be hidden.
    IBOutlet UILabel *statusLabel;
    IBOutlet UILabel *fileIdLabel;
    IBOutlet UILabel *firstFormantLabel;
    IBOutlet UILabel *secondFormantLabel;
    IBOutlet UILabel *thirdFormantLabel;
    IBOutlet UILabel *fourthFormantLabel;
    
    IBOutlet UIButton *liveToggleButton;
    
    IBOutlet UIButton *prevSegmentButton;
    IBOutlet UIButton *nextSegmentButton;
    IBOutlet UIButton *lastSegmentButton;
    
    IBOutlet UILabel *sliderLabel;
    IBOutlet UISlider *thresholdSlider;
    IBOutlet UIButton *showOrigButton;
    IBOutlet UIButton *showNormButton;
    IBOutlet UIButton *showVowelButton;
    IBOutlet UIButton *showSpecButton;
    IBOutlet UIButton *showLPCButton;
    
    int dummyTimerTickCounter;
    BOOL liveSpeechSegments;               // Whether we are processing live speech or stored samples.
    int soundFileIdentifier;               // Which stored file (1 out of 7) is being processed
    int displayIdentifier;                 // What type of information (1 out of 5) is to be displayed in plotView.
    
    NSArray *soundFileBaseNames;           // Array of names of 7 stored sound files.
}

@property (nonatomic, retain) UIImageView *indicatorImageView;
@property (nonatomic, retain) NSTimer *masterTimer;

@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) UILabel *fileIdLabel;

@property (nonatomic, retain) UILabel *firstFormantLabel;
@property (nonatomic, retain) UILabel *secondFormantLabel;
@property (nonatomic, retain) UILabel *thirdFormantLabel;
@property (nonatomic, retain) UILabel *fourthFormantLabel;

@property (nonatomic, retain) UIButton *liveToggleButton;
@property (nonatomic, retain) UIButton *prevSegmentButton;
@property (nonatomic, retain) UIButton *nextSegmentButton;
@property (nonatomic, retain) UIButton *lastSegmentButton;

@property (nonatomic, retain) UILabel *sliderLabel;
@property (nonatomic, retain) UISlider *thresholdSlider;
@property (nonatomic, retain) UIButton *showOrigButton;
@property (nonatomic, retain) UIButton *showNormButton;
@property (nonatomic, retain) UIButton *showVowelButton;
@property (nonatomic, retain) UIButton *showSpecButton;
@property (nonatomic, retain) UIButton *showLPCButton;

-(IBAction) processThresholdSlider;
-(IBAction) processLiveToggleSwitch;

-(IBAction) processPrevSegment;
-(IBAction) processNextSegment;
-(IBAction) processLastSegment;

-(void) processRawBuffer;

-(IBAction) showOrig;
-(IBAction) showTrimmed;
-(IBAction) showLPC;
-(IBAction) showSpectrum;
-(IBAction) showFormants;

-(void) displayFormantFrequencies;


@end
