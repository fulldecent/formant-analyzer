//
//  SpeechAnalyzer.h
//  FormantPlotter
//
//  Created by William Entriken on 1/19/15.
//  Copyright (c) 2015 William Entriken. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpeechAnalyzer : NSObject

/** 
 * Load speech for processing
 * @param int16Samples A data stream of raw audio samples
 */
- (void)loadData:(NSData *)int16Samples;

/**
 * Reduce horizontal resolution of signal for plotting, returns NO on error
 * @param int16Samples A data stream of raw audio samples
 * @param complete Block will receive int16 sample data of the downsampled signal
 */
- (void)downsampleToSamples:(int)samples onCompletion:(void(^)(NSData *int16Samples))complete;

/**
 * Find start and finish points representing vowel signal in speech data
 * @param complete Block will receive two floats on a scale of [0, 1] representing the full signal
 */
- (void)computeTrimPointsOnCompletion:(void(^)(NSNumber *start, NSNumber *finish))complete;

/**
 * Find LPC coefficients from the signal
 * @param complete Block will receive NSArray of NSNumbers containing the coefs
 */
- (void)findLpcCoefficientsOnCompletion:(void(^)(NSArray *coefficients))complete;

/**
 * Find the frequency response of the signal synthesized with above LPC coefficients
 * calculated in 5 Hz intervals, amplitude is [0,1]
 * @param complete Block will receive NSArray of NSNumbers containing response
 */
- (void)synthesizedFrequencyResponse:(void(^)(NSArray *response))complete;

/**
 * Find the first several formant frequencies (in Hz)
 * @param complete Block will receive NSArray of NSNumbers containing response
 */
- (void)findFormants:(void(^)(NSArray *formants))complete;

@end
