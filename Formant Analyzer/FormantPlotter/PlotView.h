//
//  PlotView.h
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/19/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

/*
 *******************************************************
 
 This is the data processing and plotting routine. It gets a value (1 out of 5) for variable
 displayIdentifier and plots data based on this value. Right now, there is a lot of test functionality
 that will be eleiminated form the final version of the project.
 
 *******************************************************
 */

#import <UIKit/UIKit.h>
#import <complex.h>


@interface PlotView : UIView

- (void)getData:(NSData *)data;
- (void)setDisplayIdentifier:(long)displayidentifier;

// Write four getter functions manually for four formant frequencies.
@property (nonatomic, readonly) double firstFFreq;
@property (nonatomic, readonly) double secondFFreq;
@property (nonatomic, readonly) double thirdFFreq;
@property (nonatomic, readonly) double fourthFFreq;
 
@property (nonatomic) short int *dataBuffer; // 16 bit signed PCM
                                             // Just a pointer. Actual buffer is in audioDeviceManager (live data) or
                                             // in firstViewController (1 of 7 stored audio files).
@property (nonatomic) long dataBufferLength;  // How many samples of the buffer needs to be processed.
@property (nonatomic) long strongStartIdx;    // Two indices in buffer representing strong section of signal.
@property (nonatomic) long strongEndIdx;
@property (nonatomic) long truncatedStartIdx; // Two indices after 15% trimming of two ends
@property (nonatomic) long truncatedEndIdx;
@property (nonatomic) long decimatedEndIdx;   // Samples in buffer after decimation by 4.

@property (nonatomic) long displayIdentifier; // What type of plot (1 out of 5) is to be displayed.


@end
