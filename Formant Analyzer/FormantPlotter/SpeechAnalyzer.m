//
//  SpeechAnalyzer.m
//  FormantPlotter
//
//  Created by William Entriken on 1/19/15.
//  Copyright (c) 2015 William Entriken. All rights reserved.
//

#import "SpeechAnalyzer.h"

@interface SpeechAnalyzer()
@property (nonatomic) NSData *int16Samples;
- (NSRange)strongSignalRange;
@end

@implementation SpeechAnalyzer

// Trim quiet parts at the ends of our signal.
// Our signal is divided into 300 chunks, and energy is computed for each.
// Leading and trailing chunks are excluded with 10dB less than the maximum energy.
// The range of the remaining signal is returned.
- (NSRange)strongSignalRange
{
    int chunkSize = 300, numChunks;
    int chunkEnergy, maxChunkEnergy = 0, chunkEnergyThreshold;
    int startSample = 0, endSample = INT_MAX;

    numChunks = self.int16Samples.length / sizeof(short int) / 300;
    
    // Find the chunk with the most energy and set energy threshold
    for (int chunkIdx = 0; chunkIdx < numChunks; chunkIdx++) {
        chunkEnergy = 0;
        for (int chunkSampleIdx = 0; chunkSampleIdx < chunkSize; chunkSampleIdx++) {
            chunkEnergy += ((short int *)self.int16Samples.bytes)[chunkIdx * chunkSize + chunkSampleIdx] / chunkSize;
        }
        maxChunkEnergy = MAX(maxChunkEnergy, chunkEnergy);
    }
    chunkEnergyThreshold = maxChunkEnergy / 10;
    
    // Find starting sample meeting minimum energy threshold
    startSample = 0;
    for (int chunkIdx = 0; chunkIdx < numChunks; chunkIdx++) {
        chunkEnergy = 0;
        for (int chunkSampleIdx = 0; chunkSampleIdx < chunkSize; chunkSampleIdx++) {
            chunkEnergy += ((short int *)self.int16Samples.bytes)[chunkIdx * chunkSize + chunkSampleIdx] / chunkSize;
        }
        if (chunkEnergy > chunkEnergyThreshold) {
            startSample = chunkIdx * chunkSize;
            break;
        }
    }
    
    // Find ending sample meeting minimum energy threshold
    endSample = self.int16Samples.length / sizeof(short int);
    for (int chunkIdx = 299; chunkIdx >= 0; chunkIdx--) {
        chunkEnergy = 0;
        for (int chunkSampleIdx = 0; chunkSampleIdx < chunkSize; chunkSampleIdx++) {
            chunkEnergy += ((short int *)self.int16Samples.bytes)[chunkIdx * chunkSize + chunkSampleIdx] / chunkSize;
        }
        if (chunkEnergy > chunkEnergyThreshold) {
            startSample = chunkIdx * chunkSize;
            endSample = (chunkIdx + 1) * chunkSize - 1;
            break;
        }
    }
    
    return NSMakeRange(startSample, endSample);
}

- (NSRange)truncateRangeTails:(NSRange)range
{
    NSUInteger newLength = range.length * 0.7;
    NSUInteger newLocation = range.location + range.length * 0.15;
    return NSMakeRange(newLocation, newLength);
}






- (void)loadData:(NSData *)int16Samples
{
    self.int16Samples = int16Samples;
}

- (void)downsampleToSamples:(int)samples onCompletion:(void(^)(NSData *int16Samples))complete
{
    
}

- (void)computeTrimPointsOnCompletion:(void(^)(NSRange trimPoints))complete;
{
    
}

- (void)findLpcCoefficientsOnCompletion:(void(^)(NSArray *coefficients))complete
{
    
}

- (void)synthesizedFrequencyResponse:(void(^)(NSArray *response))complete
{
    
}

- (void)findFormants:(void(^)(NSArray *formants))complete
{
    
}


@end
