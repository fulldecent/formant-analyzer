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
@property (nonatomic) NSRange strongSignalRangeCached;
- (NSRange)strongSignalRange;
@end

@implementation SpeechAnalyzer

+ (SpeechAnalyzer *)analyzerWithData:(NSData *)int16Samples
{
    SpeechAnalyzer *retval = [[SpeechAnalyzer alloc] init];
    [retval loadData:int16Samples];
    return retval;
}

- (NSNumber *)totalSamples
{
    return @(self.int16Samples.length / 2);
}

// Trim quiet parts at the ends of our signal.
// Our signal is divided into 300 chunks, and energy is computed for each.
// Leading and trailing chunks are excluded with 10dB less than the maximum energy.
// The range of the remaining signal is returned.
- (NSRange)strongSignalRange
{
    if (self.strongSignalRangeCached.length) {
        return self.strongSignalRangeCached;
    }
    
    long numChunks = 300;
    long chunkEnergy, chunkEnergyThreshold;
    long maxChunkEnergy = 0;
    long startSample = 0, endSample = INT_MAX;
    long chunkSize;
    short int *dataBuffer = (short int*)self.int16Samples.bytes;
    chunkSize = self.int16Samples.length / sizeof(short int) / numChunks;

    // Find the chunk with the most energy and set energy threshold
    for (int chunkIdx = 0; chunkIdx < numChunks; chunkIdx++) {
        chunkEnergy = 0;
        for (int chunkSampleIdx = 0; chunkSampleIdx < chunkSize; chunkSampleIdx++) {
            chunkEnergy += dataBuffer[chunkIdx * chunkSize + chunkSampleIdx] * dataBuffer[chunkIdx * chunkSize + chunkSampleIdx] / 1000;
        }
        maxChunkEnergy = MAX(maxChunkEnergy, chunkEnergy);
    }
    
    chunkEnergyThreshold = maxChunkEnergy / 10;
    
    // Find starting sample meeting minimum energy threshold
    startSample = 0;
    for (int chunkIdx = 0; chunkIdx < numChunks; chunkIdx++) {
        chunkEnergy = 0;
        for (int chunkSampleIdx = 0; chunkSampleIdx < chunkSize; chunkSampleIdx++) {
            chunkEnergy += dataBuffer[chunkIdx * chunkSize + chunkSampleIdx] * dataBuffer[chunkIdx * chunkSize + chunkSampleIdx] / 1000;
        }
        if (chunkEnergy > chunkEnergyThreshold) {
            startSample = chunkIdx * chunkSize;
            break;
        }
    }
    
    // Find ending sample meeting minimum energy threshold
    endSample = self.int16Samples.length / sizeof(short int);
    for (long chunkIdx = numChunks-1; chunkIdx >= 0; chunkIdx--) {
        chunkEnergy = 0;
        for (int chunkSampleIdx = 0; chunkSampleIdx < chunkSize; chunkSampleIdx++) {
            chunkEnergy += dataBuffer[chunkIdx * chunkSize + chunkSampleIdx] * dataBuffer[chunkIdx * chunkSize + chunkSampleIdx] / 1000;
        }
        if (chunkEnergy > chunkEnergyThreshold) {
            endSample = (chunkIdx + 1) * chunkSize - 1;
            break;
        }
    }
    
    self.strongSignalRangeCached = NSMakeRange(startSample, endSample-startSample);
    return self.strongSignalRangeCached;
}

// Removes 15% off each end of a range
- (NSRange)truncateRangeTails:(NSRange)range
{
    NSUInteger newLength = range.length * 0.7;
    NSUInteger newLocation = range.location + range.length * 0.15;
    return NSMakeRange(newLocation, newLength);
}

- (id)init
{
    self = [super init];
    if (self) {
        self.strongSignalRangeCached = NSMakeRange(0, 0);
    }
    return self;
}



- (void)loadData:(NSData *)int16Samples
{
    self.int16Samples = int16Samples;
    self.strongSignalRangeCached = NSMakeRange(0, 0);
}

/**
 * Reduce horizontal resolution of signal for plotting, returns NO on error
 */
- (NSArray *)downsampleToSamples:(int)samples
{
    short int *dataBuffer = (short int*)self.int16Samples.bytes;
    NSRange strongRange = [self strongSignalRange];
    long strongStartIdx = strongRange.location;
    long strongEndIdx = strongRange.location + strongRange.length;
    long chunkSamples = (strongEndIdx - strongStartIdx) / 400;
    NSMutableArray *plottableValuesHigh = [NSMutableArray array];
    
    for (long chunkIdx=0; chunkIdx<400; chunkIdx++) {
        long chunkMaxValue = 0;
        for (long j=0; j<chunkSamples; j++) {
            long dataBufferIdx = j + strongStartIdx + chunkIdx*chunkSamples;
            chunkMaxValue = MAX(chunkMaxValue, dataBuffer[dataBufferIdx]);
        }
        [plottableValuesHigh addObject:@(chunkMaxValue)];
    }
    return plottableValuesHigh;
}

/**
 * Find start and finish points representing vowel signal in speech data
 */
- (NSRange)computeTrimPoints
{
    NSRange range = [self strongSignalRange];
    range = [self truncateRangeTails:range];
    return range;
}

/**
 * Find LPC coefficients from the signal
 */
- (NSArray *)findLpcCoefficients
{
    return nil;
}

/**
 * Find the frequency response of the signal synthesized with above LPC coefficients
 * calculated in 5 Hz intervals, amplitude is [0,1]
 */
- (NSArray *)synthesizedFrequencyResponse
{
    return nil;
}

/**
 * Find the first several formant frequencies (in Hz)
 */
- (NSArray *)findFormants
{
    return nil;
}


@end
