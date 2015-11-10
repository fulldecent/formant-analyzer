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

//TODO: make this private
/**
 * Load speech for processing
 * @param int16Samples A data stream of raw audio samples
 */
- (void)loadData:(NSData *)int16Samples;

// TMP private
- (NSData *)int16SamplesDecimated;

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
- (NSRange)vowelRange;

/**
 * Find LPC coefficients from the signal
 */
- (NSArray *)lpcCoefficients;

/**
 * Find the frequency response of the signal synthesized with above LPC coefficients
 * calculated in 5 Hz intervals, amplitude is [0,1]
 */
- (NSArray *)synthesizedFrequencyResponse;

/**
 * Finds the first four formants and cleans out negatives, and other problems
 * Return is array of formants in Hz
 */
- (NSArray *)findCleanFormants;

/**
 * Heart of Laguerre algorithm. Solved the polynomial equation of a certain order.
 * This functions is called repeatedly to find all the complex roots one by one.
 */
+ (_Complex double)laguer:(_Complex double *)a currentOrder:(int)m;

/**
 * Following function implement Laguerre root finding algorithm. It uses a lot of
 * complex variables and operations of complex variables. It does not implement
 * root polishing so answers are not very accurate.
 * Input: pCoeff
 */
+ (double *)findFormants:(_Complex double*)a;

@end
