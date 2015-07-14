//
//  PlotView.m
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/19/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "PlotView.h"
#import "SpeechAnalyzer.h"

// A few constants to be used in LPC and Laguerre algorithms.
#define ORDER 20
#define EPS 2.0e-6
#define EPSS 1.0e-7
#define MR 8
#define MT 10
#define MAXIT (MT*MR)

@interface PlotView()
- (void)removeSilence;
- (void)removeTails;
- (void)decimateDataBuffer;
- (double *)findFormants:(_Complex double*) pCoeff NS_RETURNS_INNER_POINTER;
- (_Complex double)laguer:(_Complex double *) a currentOrder:(int) m;

@property (nonatomic) SpeechAnalyzer *speechAnalyzer;

@property (nonatomic) double firstFFreq;
@property (nonatomic) double secondFFreq;
@property (nonatomic) double thirdFFreq;
@property (nonatomic) double fourthFFreq;
@end


@implementation PlotView

// Gets pointer to the start of audio data and the length of the buffer.
- (void)getData:(NSData *)data
{
    self.dataBufferLength = data.length / sizeof(short int);
    self.dataBuffer = malloc(data.length);
    [data getBytes:self.dataBuffer length:data.length];

    self.speechAnalyzer = [[SpeechAnalyzer alloc] init];
    [self.speechAnalyzer loadData:data];
}

// Main processing and display routine.
- (void)drawRect:(CGRect)rect
{
    long i, j, dummo;
    
    double *formantFrequencies;
    double dummyFrequency;
    
    // Before drawing anything, remove old subviews to clear the plotView UIView window.
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    switch (self.displayIdentifier) {
            
        case 0: break;
            
        case 1: break;
            
        case 2: break;
            
        case 3:
        {
            // Here we find complex roots from the LP filter to find formant frequencies. 
            // First find LPCoefficients by repeating a few blocks given above.
            
            // First we find the truncating start and end indices
            [self removeSilence];
            [self removeTails];
            [self decimateDataBuffer];
            
            // Find ORDER+1 autocorrelation coefficient
            double *Rxx = (double *)(malloc((ORDER + 1) * sizeof(double)));
            double *pCoeff = (double *)(malloc((ORDER + 1) * sizeof(double))); 
            
            for (int delayIdx = 0; delayIdx <= ORDER; delayIdx++) {
                double corrSum = 0;
                for (int dataIdx = 0; dataIdx < (self.decimatedEndIdx - delayIdx); dataIdx++) {
                    corrSum += (self.dataBuffer[dataIdx] * self.dataBuffer[dataIdx + delayIdx]);
                }
                
                Rxx[delayIdx] = corrSum;
            }
            
            // Now solve for the predictor coefficiens.
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
            
            formantFrequencies = [self findFormants:compCoeff];
            
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
            
            // Now assign FFreq values so that they can be viewed in calling class
            self.firstFFreq = formantFrequencies[1];
            self.secondFFreq = formantFrequencies[2];
            self.thirdFFreq = formantFrequencies[3];
            self.fourthFFreq = formantFrequencies[4];
            
            // Now, we add an image to current view to plot location of first two formants
            CGRect backgroundRect = backgroundRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
            UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:backgroundRect];
            
            [backgroundImageView setImage:[UIImage imageNamed:@"vowelPlotBackground.png"]];
            [self addSubview:backgroundImageView];
            
            // Perform computations and add a marker on top.
            // We need to shift and scale our values to precisely mark the axis on image
            // Top left corner of actual plot rectangle is at (40,6) from top left corner of figure.
            // The plot rectangle has dimensions of 251x175. The plot extent on x-axis is 0-1400
            // The plot extent on y-axis is 500-4000 (logarithmic)
                        
            // If FF[2] is too close to FF[1], use FF[3] for vertical axis.
            
            float plottingX = formantFrequencies[1];
            float plottingY = formantFrequencies[2];
            if (formantFrequencies[2] <= 1.6*formantFrequencies[1])
                plottingY = formantFrequencies[3];
            //plottingX = 0;    // hard code these to graph extremes
            //plottingY = 4000; // and fuck with below constants to get graph lined up
            plottingX = backgroundImageView.frame.size.width*0.040 + plottingX/1400*(backgroundImageView.frame.size.width*0.92);
            plottingY = backgroundImageView.frame.size.height * 0.94 - log(plottingY)*22.8;
            CGRect markerRect = CGRectMake(plottingX, plottingY, 10.0, 10.0);
            UIImageView *markerImageView = [[UIImageView alloc] initWithFrame:markerRect];
            [markerImageView setImage:[UIImage imageNamed:@"second.png"]];
            [self addSubview:markerImageView];
            
            /*
            if (formantFrequencies[2] > 1.6*formantFrequencies[1]) {
                CGRect markerRect = CGRectMake(40.0 - 5.0 + 251.0 * formantFrequencies[1]/1400.0, 181.0 - 5.0 - (log(formantFrequencies[2]) - log(500.0))*175.0/log(8.0), 10.0, 10.0);
                UIImageView *markerImageView = [[UIImageView alloc] initWithFrame:markerRect];
                
                [markerImageView setImage:[UIImage imageNamed:@"second.png"]];
                [self addSubview:markerImageView];
            }
            else
            {
                CGRect markerRect1 = CGRectMake(40.0 - 5.0 + 251.0 * formantFrequencies[1]/1400.0, 181.0 - 5.0 - (log(formantFrequencies[3]) - log(500.0))*175.0/log(8.0), 10.0, 10.0);
                
                UIImageView *markerImageView = [[UIImageView alloc] initWithFrame:markerRect1];
                
                [markerImageView setImage:[UIImage imageNamed:@"second.png"]];
                [self addSubview:markerImageView];
            }
             */
            
            // Free memory allocated by our routine
            free(Rxx);
            free(pCoeff);
            free(compCoeff);
        }
            
            break;
            
        default:
            break;
    }
}

// Removes silence on both ends of speech buffer. We divide
// the given buffer into 300 chunks and compute energy in each chunk. 
// Then maximum of the chunk energies is computed.
// Only those chunks are part of strong speech segment 
// which have at least 10% energy of the maximum chunk energy.

- (void)removeSilence
{
    NSRange strongRange = [self.speechAnalyzer strongSignalRange];
    self.strongStartIdx = strongRange.location;
    self.strongEndIdx = strongRange.location + strongRange.length;
}

// Removes 15% from both ends of strong section of the buffer
- (void)removeTails
{
    NSRange strongRange = [self.speechAnalyzer strongSignalRange];
    NSRange truncated = [self.speechAnalyzer truncateRangeTails:strongRange];
    self.truncatedStartIdx = truncated.location;
    self.truncatedEndIdx = truncated.location + truncated.length;
}

// Decimates the DataBuffer by factor of 4 and sets the value of self.decimatedEndIdx
- (void)decimateDataBuffer
{
    int dumidx;
    
    for (dumidx=0; dumidx < (self.truncatedEndIdx - self.truncatedStartIdx)/4; dumidx++) {
        self.dataBuffer[dumidx] = self.dataBuffer[4*dumidx + self.truncatedStartIdx];
    }
    
    self.decimatedEndIdx = dumidx - 1;
}

// Following function implement Laguerre root finding algorithm. It uses a lot of
// complex variables and operations of complex variables. It does not implement 
// root polishing so answers are not very accurate.

-(double *) findFormants:(_Complex double*) a;
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
    
    for (j = ORDER ; j >= 1 ; j--) 
    {
        x = [self laguer:ad currentOrder:j];
        
        // If imaginary part is very small, ignore it
        if (fabs(cimag(x)) <= 2.0*EPS*fabs(creal(x)))
        {
            x = creal(x) + 0.0 * I;
        }
        
        roots[j] = x;
                
        // Perform forward deflation. Divide by the factor of the root found above
        b = ad[j]; 
        for (jj = j-1 ; jj >= 0 ; jj--) 
        {
            c = ad[jj]; 
            ad[jj] = b; 
            b = x * b + c;
        }
    }
    
    // Find real-frequencies corresponding to all roots and fill the array.
    
    // Allocate space for real-world frequencies
    double *formantFrequencies = (double *)(malloc((ORDER+1) * sizeof(double)));
    
    for (int dummo=0; dummo<=ORDER; dummo++) 
    {
        formantFrequencies[dummo] = 0.0;
    }
    
    for (int dummo=0; dummo<=ORDER; dummo++) 
    {
        formantFrequencies[dummo] = 5512.5 * carg(roots[dummo]) / M_PI;
    }
    
    return formantFrequencies;
}

// Heart of Laguerre algorithm. Solved the polynomial equation of a certain order.
// This functions is called repeatedly to find all the complex roots one by one.

-(_Complex double) laguer:(_Complex double *) a currentOrder:(int) m;
{    
    int iter , j; 
    double abx , abp , abm , err; 
    _Complex double dx , x , x1 , b , d , f , g , h , sq , gp , gm , g2; 
    static float frac[MR+1] = {0.0,0.5,0.25,0.75,0.13,0.38,0.62,0.88,1.0};
        
    x = 0.0 + 0.0 * I;
    
    for (iter = 1 ; iter <= MAXIT ; iter++) 
    {
        b = a[m]; 
        err = cabs(b); 
        d = f = 0.0 + 0.0 * I;
        abx = cabs(x);
        
        for (j = m - 1 ; j >= 0 ; j--) 
        {
            f = x * f + d; 
            d = x * d + b; 
            b = x * b + a[j]; 
            err = cabs(b) + abx * err;
        } 
        
        err *= EPSS;
        if (cabs(b) <= err)    // error is small, return x even if iterations are not exhausted
        {
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


@end
