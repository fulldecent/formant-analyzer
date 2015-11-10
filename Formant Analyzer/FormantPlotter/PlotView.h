//
//  PlotView.h
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/19/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <complex.h>


@interface PlotView : UIView

// Needs at least two or three formants to plot, contents are (NSNumber *)
@property (nonatomic) NSArray *formants;

@end
