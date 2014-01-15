//
//  FormantPlotterViewController.h
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/14/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HelpViewController.h"
#import "PlotView.h"

@interface FormantPlotterViewController : UIViewController {
    
    IBOutlet HelpViewController *helpViewController;
    IBOutlet PlotView *plotView;
    
    IBOutlet UIImageView *indicatorImageView;
    IBOutlet UILabel *statusLabel;
    IBOutlet UILabel *firstFormantLabel;
    IBOutlet UILabel *secondFormantLabel;
    IBOutlet IBOutlet UILabel *thirdFormantLabel;
    IBOutlet UILabel *fourthFormantLabel;
    
}

@property (nonatomic, retain) UIImageView *indicatorImageView;
@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) UILabel *firstFormantLabel;
@property (nonatomic, retain) UILabel *secondFormantLabel;
@property (nonatomic, retain) UILabel *thirdFormantLabel;
@property (nonatomic, retain) UILabel *fourthFormantLabel;

-(IBAction) showHelp;

@end
