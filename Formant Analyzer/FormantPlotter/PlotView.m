//
//  PlotView.m
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/19/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "PlotView.h"


@implementation PlotView

// Four getter functions to export four formant frequencies back to firstViewController
-(double) firstFFreq
{
    return firstFFreq;
}

-(double) secondFFreq
{
    return secondFFreq;
}

-(double) thirdFFreq
{
    return thirdFFreq;
}

-(double) fourthFFreq
{
    return fourthFFreq;
}

// A setter function for displayIdentifier
-(void)setDisplayIdentifier:(int)displayidentifier
{
    displayIdentifier = displayidentifier;
}

// Gets pointer to the start of audio data and the length of the buffer.
-(void)getData:(short int *)databuffer withLength:(int)length
{
    dataBuffer = databuffer;
    dataBufferLength = length;
}

// Main processing and display routine. 
- (void)drawRect:(CGRect)rect
{
    UIColor *mycolor;
    CGPoint startPoint, endPoint;
    int i, j, k, dummo, degIdx, chunkIdx, chunkSize;
    short int chunkMinValue, chunkMaxValue;
    
    int maxSampleValue;
    int maxEnergyValue, chunkEnergy;
    
    // A few variable used in plotting of H(w).
    double omega, realHw, imagHw, maxFreqResp, minFreqResp, freqRespScale;
    
    double *formantFrequencies;
    double dummyFrequency;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat dashPattern[2];
    
    // Before drawing anything, remove old subviews to clear the plotView UIView window.
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    switch (displayIdentifier) {
            
        case 1:
        {
            // Here we show the speech segment. Since we have only 300 pixels horizontally,            
            // we divide the strong buffer into 300 chunks and find absolute maximum values
            // in each chunk. Only these values are plotted as it is not practical to display 
            //hundreds of samples that get mapped to one pixel.
            
            [self removeSilence];    // Remove dead silence on both ends of the buffer to get strong buffer
            
            chunkSize = (strongEndIdx - strongStartIdx)/self.frame.size.width;
            NSLog(@"Start/end indices before 15%% clipping are at %d and %d",strongStartIdx,strongEndIdx);
            
            maxSampleValue = 0;
            for (j = strongStartIdx;  j < strongEndIdx; j++) {
                maxSampleValue = MAX(maxSampleValue, abs(dataBuffer[j]));
            }
            
            mycolor = [UIColor greenColor];
            CGContextSetLineWidth(ctx, 1.0);
            CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
            CGContextSetFillColorWithColor(ctx, mycolor.CGColor);
            
            startPoint = CGPointMake(0, 100);
            CGContextMoveToPoint(ctx, startPoint.x, startPoint.y);
            
            for (chunkIdx=0; chunkIdx<300; chunkIdx++) {
                chunkMinValue = 32700;
                chunkMaxValue = -32700;
                for (j=0; j<chunkSize; j++) {
                    chunkMinValue = MIN(chunkMinValue, dataBuffer[j + strongStartIdx + chunkIdx*chunkSize]);
                    chunkMaxValue = MAX(chunkMaxValue, dataBuffer[j + strongStartIdx + chunkIdx*chunkSize]);
                }
                
                if (maxSampleValue == 0) {
                    maxSampleValue = 1;
                }
                
                endPoint = CGPointMake(chunkIdx, 100 + chunkMinValue*115/maxSampleValue);
                CGContextMoveToPoint(ctx, startPoint.x, startPoint.y);
                CGContextAddLineToPoint(ctx, endPoint.x, endPoint.y);
                startPoint = endPoint;
                endPoint = CGPointMake(chunkIdx, 100 + chunkMaxValue*115/maxSampleValue);
                CGContextMoveToPoint(ctx, startPoint.x, startPoint.y);
                CGContextAddLineToPoint(ctx, endPoint.x, endPoint.y);
                CGContextStrokePath(ctx);
            }
            
            // Now draw a black horizontal line at the center of the plot
            mycolor = [UIColor blackColor];
            
            CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
            CGContextSetLineWidth(ctx, 1.0);
            CGContextMoveToPoint(ctx, 0, 100);
            CGContextAddLineToPoint(ctx, 320, 100);
            CGContextStrokePath(ctx);
        }
            break;
            
        case 2:
        {
            // Here we truncate 15% from head and tail to show central part of valid speech. 
            // We do not plot maximum values of the waveform. Instead we plot a bar graph type
            // display derived from energies in 60 chunks. Each bar is 5 pixel wide.
            
            [self removeSilence];
            [self removeTails];
            
            NSLog(@"Start/end indices after  15%% clipping are at %d and %d\n",truncatedStartIdx,truncatedEndIdx);
            NSLog(@"\n");
            
            // Now display bar-graph type plot for energy in total of 60 chunks. 
            chunkSize = (strongEndIdx - strongStartIdx)/(self.frame.size.width/5);
            maxEnergyValue = 0;
            for (chunkIdx=0; chunkIdx<60; chunkIdx++) {
                chunkEnergy = 0;
                for (j=0; j<chunkSize; j++) {
                    chunkEnergy += dataBuffer[j + strongStartIdx + chunkIdx*chunkSize] * dataBuffer[j + strongStartIdx + chunkIdx*chunkSize]/10000;
                }
                maxEnergyValue = MAX(maxEnergyValue, chunkEnergy);
            }
            
            if (maxEnergyValue == 0) {
                maxEnergyValue = 1;
            }
            
            for (chunkIdx=0; chunkIdx<60; chunkIdx++) {
                chunkEnergy = 0;
                for (j=0; j<chunkSize; j++) {
                    chunkEnergy += dataBuffer[j + strongStartIdx + chunkIdx*chunkSize] * dataBuffer[j + strongStartIdx + chunkIdx*chunkSize]/10000;
                }
                
                if (chunkIdx > 8 && chunkIdx < 51) {
                    mycolor = [UIColor greenColor];
                    CGContextSetLineWidth(ctx, 1.0);
                    CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
                    CGContextSetFillColorWithColor(ctx, mycolor.CGColor);
                    CGContextFillRect(ctx, CGRectMake(chunkIdx*5, 100 - 95*chunkEnergy/maxEnergyValue, 5, 190*chunkEnergy/maxEnergyValue));
                    CGContextStrokePath(ctx);
                }
                else
                {
                    mycolor = [UIColor grayColor];
                    CGContextSetLineWidth(ctx, 1.0);
                    CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
                    CGContextSetFillColorWithColor(ctx, mycolor.CGColor);
                    CGContextFillRect(ctx, CGRectMake(chunkIdx*5, 100 - 95*chunkEnergy/maxEnergyValue, 5, 190*chunkEnergy/maxEnergyValue));
                    CGContextStrokePath(ctx);   
                }
            }
            
            // Now draw a black horizontal line at the center of the plot
            mycolor = [UIColor blackColor];
            
            CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
            CGContextSetLineWidth(ctx, 1.0);
            CGContextMoveToPoint(ctx, 0, 100);
            CGContextAddLineToPoint(ctx, 320, 100);
            CGContextStrokePath(ctx);
        }
            break;
            
        case 3:
        {
            // Here we find linear prediction coefficients using an iterative procedure of Levinson 
            
            // First we find the truncating start and end indices. We do not appy any window function 
            // to smooth out the sudden transition at the end of the chunk.
            [self removeSilence];
            [self removeTails];
            [self decimateDataBuffer];
            
            // Find ORDER+1 autocorrelation coefficient
            double *Rxx = (double *)(malloc((ORDER + 1) * sizeof(double)));
            double *pCoeff = (double *)(malloc((ORDER + 1) * sizeof(double))); 
            
            // Find all the correlation coefficients.
            for (int delayIdx = 0; delayIdx <= ORDER; delayIdx++) {
                double corrSum = 0;
                for (int dataIdx = 0; dataIdx < (decimatedEndIdx - delayIdx); dataIdx++) {
                    corrSum += (dataBuffer[dataIdx] * dataBuffer[dataIdx + delayIdx]);
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
            
            // Now plot predictor coefficients. Thick lines are used to represent the LPC coefficients.
            
            double maxCoeff = 0.0;
            
            for (int delayIdx = 0; delayIdx <= ORDER; delayIdx++) {
                maxCoeff = MAX(maxCoeff, fabs(pCoeff[delayIdx]));
            }
            
            double lineSpacing = 280.0/ORDER;
            
            // Plot Rxx in the UIView window
            mycolor = [UIColor blackColor];
            CGContextSetLineWidth(ctx, 3.0);
            CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
            CGContextSetFillColorWithColor(ctx, mycolor.CGColor);
            
            for (int delayIdx = 0; delayIdx <= ORDER; delayIdx++) {
                CGContextMoveToPoint(ctx, 10 + delayIdx * lineSpacing, 100);
                CGContextAddLineToPoint(ctx, 10 + delayIdx * lineSpacing, 100 - pCoeff[delayIdx] * 95/maxCoeff);
                CGContextStrokePath(ctx);
            }
            
            mycolor = [UIColor blueColor];
            
            CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
            CGContextSetLineWidth(ctx, 1.0);
            CGContextMoveToPoint(ctx, 0, 100);
            CGContextAddLineToPoint(ctx, 320, 100);
            CGContextStrokePath(ctx);
            
            // Free two buffers started with malloc()
            free(Rxx);
            free(pCoeff);
        }
            break;
            
        case 4:
        {
            // Here we find frequency response of the LPC synthesis filter. It should have
            // peaks where formant frequencies are located.
            
            // Following few blocks are being repeated from case 3: block. We could have
            // made functions for these operatioins but a simpler duplication saves time.
            
            // First we find the truncating start and end indices
            [self removeSilence];
            [self removeTails];
            [self decimateDataBuffer];
            
            // Find ORDER+1 autocorrelation coefficient
            double *Rxx = (double *)(malloc((ORDER + 1) * sizeof(double)));
            double *pCoeff = (double *)(malloc((ORDER + 1) * sizeof(double))); 
            
            for (int delayIdx = 0; delayIdx <= ORDER; delayIdx++) {
                double corrSum = 0;
                for (int dataIdx = 0; dataIdx < (decimatedEndIdx - delayIdx); dataIdx++) {
                    corrSum += (dataBuffer[dataIdx] * dataBuffer[dataIdx + delayIdx]);
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
            
            // Now we find frequency response of the inverse of the predictor filter   
            
            double *freqResponse = (double *)(malloc((300) * sizeof(double))); 
            for (degIdx=0; degIdx < 300; degIdx++) {
                omega = degIdx * M_PI / 330.0;
                realHw = 1.0;
                imagHw = 0.0;
                
                for (k = 1 ; k <= ORDER ; k++) {
                    realHw = realHw + pCoeff[k] * cos(k * omega);
                    imagHw = imagHw - pCoeff[k] * sin(k * omega);
                }
                
                freqResponse[degIdx] = 20*log10(1.0 / sqrt(realHw * realHw + imagHw * imagHw));
            }
            
            // Now plot the frequency response
            maxFreqResp = -100.0;
            minFreqResp = 100.0;
            
            for (degIdx = 0; degIdx < 300; degIdx++) {
                maxFreqResp = MAX(maxFreqResp, freqResponse[degIdx]);
                minFreqResp = MIN(minFreqResp, freqResponse[degIdx]);
            }
            
            freqRespScale = 180.0 / (maxFreqResp - minFreqResp);
            
            mycolor = [UIColor blackColor];
            CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
            CGContextSetLineWidth(ctx, 2.0);
            startPoint = CGPointMake(0, 190 - freqRespScale * (freqResponse[0] - minFreqResp));
            
            for (chunkIdx=0; chunkIdx<300; chunkIdx++) {
                endPoint = CGPointMake(chunkIdx, 190 - freqRespScale * (freqResponse[chunkIdx] - minFreqResp));
                CGContextMoveToPoint(ctx, startPoint.x, startPoint.y);
                CGContextAddLineToPoint(ctx, endPoint.x, endPoint.y);
                startPoint = endPoint;
            }
            
            CGContextStrokePath(ctx);
            
            // Draw four dashed vertical lines at 1kHz, 2kHz, 3kHz, and 4 kHz.
            mycolor = [UIColor blueColor];
            
            dashPattern[0] = 3.0;
            dashPattern[1] = 3.0;
            CGContextSetLineDash(ctx, 0, dashPattern, 1);
            CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
            for (k=1; k<5; k++) {
                CGContextMoveToPoint(ctx, 60*k - 1, 0);
                CGContextAddLineToPoint(ctx, 60*k - 1, 200);
                CGContextStrokePath(ctx);
            }
            
            // Free two buffers started with malloc()
            free(Rxx);
            free(pCoeff);
            free(freqResponse);
            
        }
            break;
            
        case 5:
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
                for (int dataIdx = 0; dataIdx < (decimatedEndIdx - delayIdx); dataIdx++) {
                    corrSum += (dataBuffer[dataIdx] * dataBuffer[dataIdx + delayIdx]);
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
                NSLog(@"Format frequency for index %d is %5.0f",dummo, formantFrequencies[dummo]);
            }
            
            // Print a blank line
            NSLog(@" ");
            
            // Now assign FFreq values so that they can be viewed in calling class
            firstFFreq = formantFrequencies[1];
            secondFFreq = formantFrequencies[2];
            thirdFFreq = formantFrequencies[3];
            fourthFFreq = formantFrequencies[4];
            
            // Now, we add an image to current view to plot location of first two formants
            CGRect backgroundRect = CGRectMake(0, 0, 300, 200);
            backgroundRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
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

// The following function removes silence on both ends of speech buffer. We divide 
// the given buffer into 300 chunks and compute energy in each chunk. 
// Then maximum of the chunk energies is computed.
// Only those chunks are part of strong speech segment 
// which have at least 10% energy of the maximum chunk energy.

-(void) removeSilence
{    
    int chunkEnergy, energyThreshold;
    int maxEnergyValue;
    int chunkIdx;
    int j;
    
    int chunkSize = dataBufferLength / 300;
    
    maxEnergyValue = 0;
    for (chunkIdx=0; chunkIdx<300; chunkIdx++) {
        chunkEnergy = 0;
        for (j=0; j<chunkSize; j++) {
            chunkEnergy += dataBuffer[j + chunkIdx*chunkSize] * dataBuffer[j + chunkIdx*chunkSize]/1000;
        }
        maxEnergyValue = MAX(maxEnergyValue, chunkEnergy);
    }
    
    energyThreshold = maxEnergyValue / 10;
    
    // Find strong starting index.
    strongStartIdx = 0;
    for (chunkIdx=0; chunkIdx<300; chunkIdx++) {
        chunkEnergy = 0;
        for (j=0; j<chunkSize; j++) {
            chunkEnergy += dataBuffer[j + chunkIdx*chunkSize] * dataBuffer[j + chunkIdx*chunkSize]/1000;
        }
        if (chunkEnergy > energyThreshold) {
            strongStartIdx = chunkIdx * chunkSize;
            strongStartIdx = MAX(0, strongStartIdx);
            break;
        }
    }
    
    // Find strong ending index
    strongEndIdx = dataBufferLength;
    for (chunkIdx = 299; chunkIdx >= 0; chunkIdx--) {
        chunkEnergy = 0;
        for (j=0; j<chunkSize; j++) {
            chunkEnergy += dataBuffer[j + chunkIdx*chunkSize] * dataBuffer[j + chunkIdx*chunkSize]/1000;
        }
        if (chunkEnergy > energyThreshold) {
            strongEndIdx = chunkIdx * chunkSize + chunkSize - 1;
            strongEndIdx = MIN(dataBufferLength, strongEndIdx);
            break;
        }
    }
}

// The follosing function removes 15% from both ends of strong section of the buffer
-(void) removeTails
{
    truncatedStartIdx = strongStartIdx + (strongEndIdx - strongStartIdx)*15/100;
    truncatedEndIdx = strongEndIdx - (strongEndIdx - strongStartIdx)*15/100;
}

// Following function decimates the DataBuffer by factor of 4 and sets the value of decimatedEndIdx
-(void) decimateDataBuffer
{
    int dumidx;
    
    for (dumidx=0; dumidx < (truncatedEndIdx - truncatedStartIdx)/4; dumidx++) {
        dataBuffer[dumidx] = dataBuffer[4*dumidx + truncatedStartIdx];
    }
    
    decimatedEndIdx = dumidx - 1;
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
