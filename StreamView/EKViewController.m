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

- (UIView *)cellForStreamView:(EKStreamView *)streamView atIndex:(NSInteger)index
{
    static NSString *CellID1 = @"MyCell1";
    static NSString *CellID2 = @"MyCell2";
    
    BOOL redCell = index % 3 == 0;
    NSString *CellID =  CellID1;
    
    MyCell *cell;
    
    cell = (MyCell *)[streamView dequeueReusableCellWithIdentifier:CellID];
    
    if (cell == nil) {
        cell = [[[MyCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100)] autorelease];
        cell.reuseIdentifier = CellID;
//        if (redCell) cell.label.textColor = [UIColor redColor];
    }
    
    cell.label.text = [NSString stringWithFormat:@"%d",index];
    
    return cell;
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
