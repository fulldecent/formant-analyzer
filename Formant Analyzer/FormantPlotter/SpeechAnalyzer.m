//
//  SpeechAnalyzer.m
//  FormantPlotter
//
//  Created by William Entriken on 1/19/15.
//  Copyright (c) 2015 William Entriken. All rights reserved.
//

#import "SpeechAnalyzer.h"

// A few constants to be used in LPC and Laguerre algorithms.
#define ORDER 20
#define EPS 2.0e-6
#define EPSS 1.0e-7
#define MR 8
#define MT 10
#define MAXIT (MT*MR)

@interface SpeechAnalyzer()
@property (nonatomic) NSData *int16Samples;
@property (nonatomic) NSData *int16SamplesDecimated;
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

- (id)init
{
    self = [super init];
    if (self) {
        self.strongSignalRangeCached = NSMakeRange(0, 0);
    }
    return self;
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

/*
 * This takes the isolated vowel range of the sound signal and reduces the sampling rate.
 * A simple, one-pass algorithm is used.
 * Because sampling rate is 44.1kHz and human speech formants are < 5kHz, quality not needed here.
 */
- (NSData *)int16SamplesDecimated
{
    if (!_int16SamplesDecimated) {
        int decimationFactor = 4; // input variable, 11025 Hz sample rate
        short int *inputDataBuffer = (short int*)self.int16Samples.bytes;
        NSRange vowelRange = [self vowelRange];
        long vowelStartIdx = vowelRange.location;
        long vowelEndIdx = vowelRange.location + vowelRange.length;
        long outputSamples = (vowelEndIdx - vowelStartIdx) / decimationFactor;
        
        NSMutableData *workingData = [NSMutableData data];
        long outputIndex;
        for (outputIndex = 0; outputIndex < outputSamples; outputIndex++) {
            [workingData appendBytes:&inputDataBuffer[4*outputIndex + vowelStartIdx] length:sizeof(short int)];
        }
        _int16SamplesDecimated = workingData;
    }
    return _int16SamplesDecimated;
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
//    NSRange strongRange = [self strongSignalRange];
    NSRange strongRange = NSMakeRange(0, self.totalSamples.doubleValue);
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
- (NSRange)vowelRange
{
    NSRange range = [self strongSignalRange];
    range = [self truncateRangeTails:range];
    return range;
}

/**
 * Find linear prediction coefficients using an iterative procedure of Levinson
 */
- (NSArray *)lpcCoefficients
{
    NSData *decimatedBufferData = self.int16SamplesDecimated;
    short int *decimatedBuffer = (short int *)decimatedBufferData.bytes;
    long decimatedBufferSamples = decimatedBufferData.length / sizeof(short int);
    
    // Find ORDER+1 autocorrelation coefficient
    // TODO: make this an nsarray
    NSMutableArray *Rxx = [NSMutableArray arrayWithCapacity:ORDER + 1];
    NSMutableArray *pCoeff = [NSMutableArray arrayWithCapacity:ORDER + 1];
    
    // Find all the correlation coefficients.
    for (int delayIdx = 0; delayIdx <= ORDER; delayIdx++) {
        double corrSum = 0;
        for (int dataIdx = 0; dataIdx < (decimatedBufferSamples - delayIdx); dataIdx++) {
            corrSum += (double)decimatedBuffer[dataIdx] * decimatedBuffer[dataIdx + delayIdx];
        }
        Rxx[delayIdx] = @(corrSum);
    }
    
    // Now solve for the predictor coefficients
    double pError = ((NSNumber *)Rxx[0]).doubleValue;      // initialize error to total power
    pCoeff[0] = @(1.0);                                    // first coefficient must be = 1
    
    // For each coefficient in turn
    for (int k = 1 ; k <= ORDER ; k++) {
        // find next reflection coeff from pCoeff[] and Rxx[]
        double rcNum = 0;
        for (int i = 1 ; i <= k ; i++) {
            rcNum -= ((NSNumber *)pCoeff[k-i]).doubleValue * ((NSNumber *)Rxx[i]).doubleValue;
        }
        
        pCoeff[k] = @(rcNum/pError);
        
        // perform recursion on pCoeff[]
        for (int i = 1 ; i <= k/2 ; i++) {
            double pci  = ((NSNumber *)pCoeff[i]).doubleValue + ((NSNumber *)pCoeff[k]).doubleValue * ((NSNumber *)pCoeff[k-i]).doubleValue;
            double pcki = ((NSNumber *)pCoeff[k-i]).doubleValue + ((NSNumber *)pCoeff[k]).doubleValue * ((NSNumber *)pCoeff[i]).doubleValue;
            pCoeff[i] = @(pci);
            pCoeff[k-i] = @(pcki);
        }
        
        // calculate residual error
        pError = pError * (1.0 - ((NSNumber *)pCoeff[k]).doubleValue * ((NSNumber *)pCoeff[k]).doubleValue);
    }
    
    // Now plot predictor coefficients. Thick lines are used to represent the LPC coefficients.
    double maxCoeff = 0.0;
    
    for (int delayIdx = 0; delayIdx <= ORDER; delayIdx++) {
        maxCoeff = MAX(maxCoeff, fabs(((NSNumber *)pCoeff[delayIdx]).doubleValue));
    }
    
    return pCoeff;
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
