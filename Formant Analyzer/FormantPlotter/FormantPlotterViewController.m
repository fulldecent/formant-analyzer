//
//  FormantPlotterViewController.m
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/14/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "FormantPlotterViewController.h"

@implementation FormantPlotterViewController
@synthesize indicatorImageView;
@synthesize statusLabel;
@synthesize firstFormantLabel;
@synthesize secondFormantLabel;
@synthesize thirdFormantLabel;
@synthesize fourthFormantLabel;

-(IBAction) showHelp
{
    [self presentModalViewController:helpViewController animated:NO];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [statusLabel setText:@"Waiting ..."];
    [firstFormantLabel setText:@"Formant 1: 360 Hz"];
    [secondFormantLabel setText:@"Formant 2: 660 Hz"];
    [thirdFormantLabel setText:@"Formant 3: 940 Hz"];
    [fourthFormantLabel setText:@"Formant 4: 1240 Hz"];
    
    [indicatorImageView setImage:[UIImage imageNamed:@"green_light.png"]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
