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

- (void)downsampleToSamples:(int)samples onCompletion:(void(^)(NSData *int16Samples))complete
{
}

- (void)computeTrimPointsOnCompletion:(void(^)(NSRange trimPoints))complete;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSRange range = [self strongSignalRange];
        range = [self truncateRangeTails:range];
        complete(range);
    });
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
