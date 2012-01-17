//
//  EKViewController.m
//  StreamView
//
//  Created by Eli Wang on 1/16/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import "EKViewController.h"
#import "MyCell.h"

@implementation EKViewController
@synthesize waterfall;

- (void)dealloc {
    [randomHeights release];
    [waterfall release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [randomHeights release];
    randomHeights = [[NSMutableArray alloc] initWithCapacity:100];
    for (int i = 0; i < 100; i++) {
        CGFloat h = arc4random() % 200 + 50.f;
        [randomHeights addObject:[NSNumber numberWithFloat:h]];
    }
    
    [waterfall reloadData];
}

- (void)viewDidUnload
{
    [self setWaterfall:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSInteger)numberOfCellsInStreamView:(EKStreamView *)streamView
{
    return [randomHeights count];
}

- (NSInteger)numberOfColumnsInStreamView:(EKStreamView *)streamView
{
    return 3;
}

- (UIView *)cellForStreamView:(EKStreamView *)streamView
{
    return [[[MyCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100)] autorelease];
}

- (CGFloat)streamView:(EKStreamView *)streamView heightForCellAtIndex:(NSInteger)index
{
    return [[randomHeights objectAtIndex:index] floatValue];
}

- (void)streamView:(EKStreamView *)streamView setContentForCell:(MyCell *)cell atIndex:(NSInteger)index
{
    cell.label.text = [NSString stringWithFormat:@"%d",index];
}

@end
