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

// A few constants to be used in LPC and Laguerre algorithms.
# define ORDER 20

#define EPS 2.0e-6 
#define EPSS 1.0e-7 
#define MR 8
#define MT 10 
#define MAXIT (MT*MR)


@interface PlotView : UIView {
    
    short int *dataBuffer;        // Just a pointer. Actual buffer is in audioDeviceManager (live data) or
                                  // in firstViewController (1 of 7 stored audio files).
    int dataBufferLength;         // How many samples of the buffer needs to be processed.
    int displayIdentifier;        // What type of plot (1 out of 5) is to be displayed.
    int strongStartIdx, strongEndIdx;           // Two indices in buffer representing strong section of signal.
    int truncatedStartIdx, truncatedEndIdx;     // Two indices after 15% trimming of two ends
    int decimatedEndIdx;                        // Samples in buffer after decimation by 4.
    double firstFFreq, secondFFreq, thirdFFreq, fourthFFreq;
}


-(void)getData:(short int *)databuffer withLength:(int)length;
-(void)setDisplayIdentifier:(int)displayidentifier;

// Write four getter functions manually for four formant frequencies.
-(double) firstFFreq;
-(double) secondFFreq;
-(double) thirdFFreq;
-(double) fourthFFreq;

-(void) removeSilence;  
-(void) removeTails;
-(void) decimateDataBuffer;

-(double *) findFormants:(_Complex double*) pCoeff;
-(_Complex double) laguer:(_Complex double *) a currentOrder:(int) m;

@end
