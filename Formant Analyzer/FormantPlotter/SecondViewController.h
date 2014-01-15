//
//  SecondViewController.h
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

/*
 *******************************************************
 
 This is the second view controller that shows a dummy help file in html format.
 It is mainly a UIWebView that displays a small html file present in main bundle.
 
 *******************************************************
 */

#import <UIKit/UIKit.h>

@interface SecondViewController : UIViewController {
    
    IBOutlet UIWebView *helpView;
    
}

@property(nonatomic, retain) UIWebView *helpView;

@end
