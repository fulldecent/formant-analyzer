//
//  SpeechAnalyzer.h
//  FormantPlotter
//
//  Created by William Entriken on 1/19/15.
//  Copyright (c) 2015 William Entriken. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpeechAnalyzer : NSObject

+ (SpeechAnalyzer *)analyzerWithData:(NSData *)int16Samples;

- (NSNumber *)totalSamples;

// MAKE THIS PRIVATE
/** 
 * Load speech for processing
 * @param int16Samples A data stream of raw audio samples
 */
- (void)loadData:(NSData *)int16Samples;

// HACK FUNCTIONS
- (NSRange)strongSignalRange;
- (NSRange)truncateRangeTails:(NSRange)range;


/**
 * Reduce horizontal resolution of signal for plotting, returns NO on error
 */
- (NSArray *)downsampleToSamples:(int)samples;

/**
 * Find start and finish points representing vowel signal in speech data
 */
- (NSRange)computeTrimPoints;

/**
 * Find LPC coefficients from the signal
 */
- (NSArray *)findLpcCoefficients;

/**
 * Find the frequency response of the signal synthesized with above LPC coefficients
 * calculated in 5 Hz intervals, amplitude is [0,1]
 */
- (NSArray *)synthesizedFrequencyResponse;

/**
 * Find the first several formant frequencies (in Hz)
 */
- (NSArray *)findFormants;


@end
