//
//  PlotView.m
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/19/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "PlotView.h"
#import "SpeechAnalyzer.h"

@implementation PlotView

// Main processing and display routine. Requires self.firstFF, self.secondFF and self.thirdFF to run
- (void)drawRect:(CGRect)rect
{
    // Before drawing anything, remove old subviews to clear the plotView UIView window.
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    if (self.formants.count < 3)
        return;

    // Now, we add an image to current view to plot location of first two formants
    CGRect backgroundRect = backgroundRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:backgroundRect];
    backgroundImageView.image = [UIImage imageNamed:@"vowelPlotBackground.png"];
    [self addSubview:backgroundImageView];
    
    // Choose the two formants we want to plot
    // If FF[2] is too close to FF[1], use FF[3] for vertical axis.
    float plottingFmtX = ((NSNumber *)self.formants[0]).floatValue;
    float plottingFmtY = ((NSNumber *)self.formants[1]).floatValue;
    if (((NSNumber *)self.formants[1]).floatValue <= 1.6 * ((NSNumber *)self.formants[0]).floatValue)
        plottingFmtY = ((NSNumber *)self.formants[2]).floatValue;
    
    // Translate from formant in Hz to x/y position as a portion of plot image
    // Need to consider scale of plot image and make it line up
    float plottingX = 0.103 + (plottingFmtX - 0) / 1200 * (0.953 - 0.103);
    float plottingY = (1.00 - 0.134) - (logf(plottingFmtY) / logf(2) - logf(500) / logf(2)) * (0.414 - 0.134);
    
    // Now translate into coordinate system of this image view
    CGRect markerRect = CGRectMake(self.frame.size.width * plottingX - 7.5,
                                   self.frame.size.height * plottingY - 7.5,
                                   15.0,
                                   15.0);
    UIImageView *markerImageView = [[UIImageView alloc] initWithFrame:markerRect];
    markerImageView.backgroundColor = [UIColor blackColor];
    [self addSubview:markerImageView];
    
    //TODO: if the f1 <= 1.6 * f2, consider plotting a second mark where the f2 actually is rathen than using f3
}

@end
