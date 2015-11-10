//
//  SpeechAnalyzer.m
//  FormantPlotter
//
//  Created by William Entriken on 1/19/15.
//  Copyright (c) 2015 William Entriken. All rights reserved.
//

#import "SpeechAnalyzer.h"
#import <complex.h>

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
@property (nonatomic) NSArray *cleanFormantsCached;
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
    pCoeff[0] = @(1.0);                                    // first coefficient must be = 1 (perfect autocorrelation)
    
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
    
    // WE hack: fix for bad coefficients, undocumented
    for (int i = 0; i <= ORDER; i++) {
        if (isnan(((NSNumber *)pCoeff[i]).doubleValue)) {
            pCoeff[i] = @(0);
        }
    }
    
    return pCoeff;
}

/**
 * Find the frequency response of the signal synthesized with above LPC coefficients
 * calculated in 5 Hz intervals, amplitude is [0,1]
 */
- (NSArray *)synthesizedFrequencyResponse
{
    double *pCoeff = (double *)(malloc((ORDER + 1) * sizeof(double)));
    NSArray *lpcCoefficients = [self lpcCoefficients];
    for (int i=0; i<=ORDER; i++) {
        pCoeff[i] = ((NSNumber *)lpcCoefficients[i]).doubleValue;
    }
    
    // Now we find frequency response of the inverse of the predictor filter
    long degIdx, k;
    
    // A few variable used in plotting of H(w).
    double omega, realHw, imagHw;
    
    NSMutableArray *freqResponse = [NSMutableArray arrayWithCapacity:300];
    
    for ( degIdx=0; degIdx < 300; degIdx++) {
        omega = degIdx * M_PI / 330.0;
        realHw = 1.0;
        imagHw = 0.0;
        
        for (k = 1 ; k <= ORDER ; k++) {
            realHw = realHw + pCoeff[k] * cos(k * omega);
            imagHw = imagHw - pCoeff[k] * sin(k * omega);
        }
        
        freqResponse[degIdx] = @(20*log10(1.0 / sqrt(realHw * realHw + imagHw * imagHw)));
    }
    
    return freqResponse;
}


/**
 * Heart of Laguerre algorithm. Solved the polynomial equation of a certain order.
 * This functions is called repeatedly to find all the complex roots one by one.
 */
+ (_Complex double)laguer:(_Complex double *)a currentOrder:(int)m
{
    int iter , j;
    double abx , abp , abm , err;
    _Complex double dx , x , x1 , b , d , f , g , h , sq , gp , gm , g2;
    static float frac[MR+1] = {0.0,0.5,0.25,0.75,0.13,0.38,0.62,0.88,1.0};
    
    x = 0.0 + 0.0 * I;
    
    for (iter = 1 ; iter <= MAXIT ; iter++) {
        b = a[m];
        err = cabs(b);
        d = f = 0.0 + 0.0 * I;
        abx = cabs(x);
        
        for (j = m - 1 ; j >= 0 ; j--) {
            f = x * f + d;
            d = x * d + b;
            b = x * b + a[j];
            err = cabs(b) + abx * err;
        }
        
        err *= EPSS;
        if (cabs(b) <= err) {    // error is small, return x even if iterations are not exhausted
            return x;
        }
        
        g = d / b;
        g2 = g * g;
        h = g2 - f / b;
        sq = csqrt( (m-1) * (m * h - g2) );
        gp = g + sq;
        gm = g - sq;
        abp = cabs(gp);
        abm = cabs(gm);
        if (abp < abm)
        {
            gp=gm;
        }
        
        dx = ((MAX(abp,abm) > 0.0 ? (m + 0.0 * I) / gp
               : (1+abx) * (cos((float)iter) + sin((float)iter) * I)));
        x1 = x - dx;
        if (creal(x) == creal(x1) && cimag(x) == cimag(x1))
        {
            return x;
        }
        
        if (iter % MT) x = x1; else x = x - frac[iter/MT] * dx;
    }
    return x;
}

/**
 * Following function implement Laguerre root finding algorithm. It uses a lot of
 * complex variables and operations of complex variables. It does not implement
 * root polishing so answers are not very accurate.
 * Input: pCoeff
 */
+ (double *)findFormants:(_Complex double*)a
{
    // Allocate space for complex roots
    _Complex double *roots = (_Complex double *)(malloc((ORDER+1) * sizeof(_Complex double)));
    
    int j , jj;
    _Complex double x, b, c;
    
    _Complex double *ad = (_Complex double *)(malloc((ORDER+1) * sizeof(_Complex double)));
    
    for (j = 0 ; j <= ORDER ; j++)
    {
        ad[j] = a[j];
    }
    
    for (j = ORDER ; j >= 1 ; j--) {
        x = [SpeechAnalyzer laguer:ad currentOrder:j];
        
        // If imaginary part is very small, ignore it
        if (fabs(cimag(x)) <= 2.0*EPS*fabs(creal(x)))
        {
            x = creal(x) + 0.0 * I;
        }
        
        roots[j] = x;
        
        // Perform forward deflation. Divide by the factor of the root found above
        b = ad[j];
        for (jj = j-1 ; jj >= 0 ; jj--) {
            c = ad[jj];
            ad[jj] = b;
            b = x * b + c;
        }
    }
    
    // Find real-frequencies corresponding to all roots and fill the array.
    
    // Allocate space for real-world frequencies
    double *formantFrequencies = (double *)(malloc((ORDER+1) * sizeof(double)));
    
    for (int dummo=0; dummo<=ORDER; dummo++) {
        formantFrequencies[dummo] = 0.0;
    }
    
    for (int dummo=0; dummo<=ORDER; dummo++) {
        formantFrequencies[dummo] = 5512.5 * carg(roots[dummo]) / M_PI;
    }
    
    return formantFrequencies;
}

/**
 * Finds the first four formants and cleans out negatives, and other problems
 * Return is array of formants in Hz
 */
- (NSArray *)findCleanFormants
{
    if (!self.cleanFormantsCached) {
        short int *decimatedBuffer = (short int *)self.int16SamplesDecimated.bytes;
        long decimatedBufferSamples = self.int16SamplesDecimated.length / sizeof(short int);
        
        long i, j, dummo;
        
        double *formantFrequencies;
        double dummyFrequency;
        
        // Here we find complex roots from the LP filter to find formant frequencies.
        // First find LPCoefficients by repeating a few blocks given above.
        
        // Find ORDER+1 autocorrelation coefficient
        double *Rxx = (double *)(malloc((ORDER + 1) * sizeof(double)));
        double *pCoeff = (double *)(malloc((ORDER + 1) * sizeof(double)));
        
        for (int delayIdx = 0; delayIdx <= ORDER; delayIdx++) {
            double corrSum = 0;
            for (int dataIdx = 0; dataIdx < (decimatedBufferSamples - delayIdx); dataIdx++) {
                corrSum += (decimatedBuffer[dataIdx] * decimatedBuffer[dataIdx + delayIdx]);
            }
            
            Rxx[delayIdx] = corrSum;
        }
        
        // Now solve for the predictor coefficients
        double pError = Rxx[0];                             // initialise error to total power
        pCoeff[0] = 1.0;                                    // first coefficient must be = 1
        
        // for each coefficient in turn
        for (int k = 1 ; k <= ORDER ; k++) {
            
            // find next reflection coeff from pCoeff[] and Rxx[]
            double rcNum = 0;
            for (int i = 1 ; i <= k ; i++)
            {
                rcNum -= pCoeff[k-i] * Rxx[i];
            }
            
            pCoeff[k] = rcNum/pError;
            
            // perform recursion on pCoeff[]
            for (int i = 1 ; i <= k/2 ; i++) {
                double pci  = pCoeff[i] + pCoeff[k] * pCoeff[k-i];
                double pcki = pCoeff[k-i] + pCoeff[k] * pCoeff[i];
                pCoeff[i] = pci;
                pCoeff[k-i] = pcki;
            }
            
            // calculate residual error
            pError = pError * (1.0 - pCoeff[k]*pCoeff[k]);
            
        }
        
        // Now work with a lot of complex variables to find complex roots of LPC filter.
        // These roots will give us formant frequencies.
        
        _Complex double *compCoeff = (_Complex double *)(malloc((ORDER + 1) * sizeof(_Complex double)));
        
        // Transfer pCoeff (real-valued) to compCoeff (complex-valued).
        for (dummo=0; dummo <= ORDER; dummo++) {
            compCoeff[dummo] = pCoeff[ORDER - dummo] + 0.0 * I;
        }
        
        // Formant frequencies are computed in a separate function.
        formantFrequencies = [SpeechAnalyzer findFormants:compCoeff];
        
        //Now clean formant frequencies. Remove all that are negative, < 50 Hz, or > (Fs/2 - 50).
        for (dummo = 1; dummo <= ORDER; dummo++) {
            if (formantFrequencies[dummo] > (5512.5 - 50.0))  formantFrequencies[dummo] = 5512.5;
            if (formantFrequencies[dummo] < 50.0)  formantFrequencies[dummo] = 5512.5;
        }
        
        // Now sort formant frequencies. Simple in-place bubble sort.
        for (i = 1 ; i <= ORDER ; i++) {
            for (j = i ; j <= ORDER ; j++) {
                if (formantFrequencies[i] > formantFrequencies[j]) {
                    dummyFrequency = formantFrequencies[i];
                    formantFrequencies[i] = formantFrequencies[j];
                    formantFrequencies[j] = dummyFrequency;
                }
            }
        }
        
        // Now list first 8 sorted frequencies.
        for (dummo = 1; dummo <= 8; dummo++) {
            NSLog(@"Format frequency for index %ld is %5.0f",dummo, formantFrequencies[dummo]);
        }
        
        // Print a blank line
        NSLog(@" ");
        
        self.cleanFormantsCached = @[@(formantFrequencies[1]),
                                     @(formantFrequencies[2]),
                                     @(formantFrequencies[3]),
                                     @(formantFrequencies[4])];
        
        // Free memory allocated by our routine
        free(Rxx);
        free(pCoeff);
        free(compCoeff);
    }
    return self.cleanFormantsCached;
}





@end
