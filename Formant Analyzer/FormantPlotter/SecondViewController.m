//
//  SecondViewController.m
//  FormantPlotter
//
//  Created by William Entriken on 1/15/14.
//  Copyright (c) 2014 William Entriken. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation SecondViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    NSString *htmlString =  [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"formant_plot_help" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    
    [self.webView loadHTMLString:htmlString baseURL:baseURL];
}

@end
