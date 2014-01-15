//
//  HelpViewController.h
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/14/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HelpViewController : UIViewController {
    
    IBOutlet UIWebView *helpWebView;
    
}

@property (nonatomic, retain) UIWebView *helpWebView;

-(IBAction) leaveHelpView;

@end
