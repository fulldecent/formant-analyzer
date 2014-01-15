//
//  FormantPlotterAppDelegate.h
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/14/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FormantPlotterViewController;

@interface FormantPlotterAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet FormantPlotterViewController *viewController;

@end
